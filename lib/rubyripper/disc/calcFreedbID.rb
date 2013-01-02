#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010  Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/disc/disc'
require 'rubyripper/preferences/main'
require 'rubyripper/system/dependency'
require 'rubyripper/system/execute'

# class that gets the freedb string
class CalcFreedbID
  include GetText
  GetText.bindtextdomain("rubyripper")

  # setup some references to needed objects
  def initialize(disc, prefs=nil, deps=nil,exec=nil)    
    @disc = disc
    @exec = exec ? exec : Execute.new()
    @prefs = prefs ? prefs : Preferences::Main.instance
    @deps = deps ? deps : Dependency.instance
    @freedbString = nil
  end

  # fetch the freedb string
  def freedbString
    getFreedbString() if @freedbString.nil?
    @freedbString
  end

  # fetch the discid
  def discid
    getFreedbString() if @freedbString.nil?
    @discid
  end

private

  # try to get the freedbstring
  def getFreedbString()
    autoCalcFreedb()

    if @freedbString.nil?
      if @prefs.debug
        puts "DEBUG: discid or cd-discid isn't found on your system!"
        puts "DEBUG: Using fallback..."
      end
      manualCalcFreedb()
    else
      @discid = @freedbString.split()[0]
    end
  end

  # try to fetch freedb string with help programs
  def autoCalcFreedb
    unmountDiscDarwin() if @deps.platform.include?('darwin')

    if @deps.installed?('discid')
      @freedbString = @exec.launch("discid #{@prefs.cdrom}")[0].chomp
    elsif @deps.installed?('cd-discid')
      @freedbString = @exec.launch("cd-discid #{@prefs.cdrom}")[0].chomp
    end

    remountDiscDarwin() if @deps.platform.include?('darwin')
  end

  # mac OS needs to unmount the disc first
  def unmountDiscDarwin
      @exec.launch("diskutil unmount #{@prefs.cdrom}")
  end

  # mac OS needs to mount the disc again
  def remountDiscDarwin
     @exec.launch("diskutil mount #{@prefs.cdrom}")
  end

  # try to calculate it ourselves, prefer cd-info if available
  def manualCalcFreedb
    @scan = @disc.advancedTocScanner
    @scan.scan
    setDiscId()
    buildFreedbString()
  end

  # The freedb checksum is calculated as follows:
  # * for each track determine the amount of seconds it starts (offset=150)
  # * then count the individual numbers up to the total
  # * For example if seconds = 338 seconds, total is added with 3+3+8=14
  def setChecksum
    total = 0
    (1..@scan.tracks).each do |tracknumber|
      seconds = (@scan.getStartSector(tracknumber) + 150) / 75
      seconds.to_s.each_char{|char| total += char.to_i}
    end

    return total
  end

  # Calculate the discid using some magic which make my brain hurt itself
  def setDiscId
    @totalSeconds = @scan.totalSectors / 75
    @discid = ((setChecksum() % 0xff) << 24 | @totalSeconds << 8 | @scan.tracks).to_s(16)
    @discid.upcase!
  end

  # now build the freedb string
  # this consists of:
  # * discid
  # * amount of tracks
  # * each starting sector, corrected with 150 offset
  # * total seconds of playtime
  def buildFreedbString
    @freedbString = String.new
    @freedbString << "#{@discid} "
    @freedbString << "#{@scan.tracks} "

    (1..@scan.tracks).each do |tracknumber|
      @freedbString << "#{@scan.getStartSector(tracknumber) + 150} "
    end

    @freedbString << "#{(@scan.totalSectors + 150) / 75}"
  end
end
