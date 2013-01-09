#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2012  Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'rubyripper/system/dependency'
require 'rubyripper/system/execute'
require 'rubyripper/modules/audioCalculations'

# This class calculates the loudness of the file
class CalcPeakLevel
  include AudioCalculations
  
  def initialize(exec=nil, deps=nil, prefs=nil)
    @exec = exec ? exec : Execute.new()
    @deps = deps ? deps : Dependency.instance()
    @prefs = prefs ? prefs : Preferences::Main.instance
  end
  
  # returns the percentage of the loudness compared to maximum
  def getPeakLevel(filename)
    if @deps.installed?('sox')
      distanceToMax = getPeakLevelSox(filename)
      getPercentage(distanceToMax)
    else
      slowManualCalculation(filename)
    end
  end
  
  private
  
  # return the (negative) number from the overall sound
  # example line is "Pk lev dB      -0.40     -0.40     -0.45"
  def getPeakLevelSox(filename)
    @exec.launch("sox \"#{filename}\" -n stats", file=false, noTranslation=true).each do |line|
      return line.split()[3].to_f if line[0..8] == "Pk lev dB"
    end
  end
  
  # distanceToMax is negative or equal to zero
  def getPercentage(distanceToMax)
    if distanceToMax == -96.00
      percentage = "0.00"
    else
      value = 100 * ((MAX_DECIBEL_LEVEL_16_BIT + distanceToMax) / MAX_DECIBEL_LEVEL_16_BIT)
      percentage = "%.2f" % [value]
    end
    return percentage
  end
  
  def slowManualCalculation(filename)
    puts "DEBUG: Start of calculatePeakLevel algorithm: #{Time.now}." if @prefs.debug

    peakLevel = 0

    File.open(filename, 'r') do |inputfile|
      inputfile.pos = BYTES_WAV_CONTAINER

      while (data = inputfile.gets)
        samples = data.unpack("v#{data.length / 2}")
        samples.each do |sample|
          peakLevel = [peakLevel, sample.abs].max
        end
      end
    end

    return peakLevel.to_f / 0xFFFF * 100

    puts "DEBUG: End of calculatePeakLevel algorithm: #{Time.now}." if @prefs.debug
  end
end
