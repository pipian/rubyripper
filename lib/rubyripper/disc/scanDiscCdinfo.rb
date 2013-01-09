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

require 'rubyripper/system/execute'
require 'rubyripper/preferences/main'
require 'rubyripper/modules/audioCalculations'

# A class that interprets the toc with the info of cd-info
# Quite reliable for detecting data tracks and generating freedb strings
# Notice that cdparanoia and cd-info might have conflicting results for
# discs with data tracks. For freedb calculation cd-info is correct, for
# detecting the audio part, cdparanoia is correct.
class ScanDiscCdinfo
  include AudioCalculations

  attr_reader :status, :version, :discMode, :deviceName, :totalSectors,
      :playtime, :audiotracks, :firstAudioTrack, :dataTracks
  
  # Cd-info starts all tracks with 2 seconds extra if compared with cdparanoia
  OFFSET_CDINFO = -150
  
  # * cdrom = a string with the location of the drive
  # * testRead = a string with output of cd-info for unit testing purposes
  def initialize(execute=nil, prefs=nil)
    @exec = execute ? execute : Execute.new() 
    @prefs = prefs ? prefs : Preferences::Main.instance
    
    @startSector = Hash.new
    @dataTracks = Array.new
  end

  # scan the contents of the disc
  def scan
    return true if @status == 'ok'
    query = @exec.launch("cd-info -C #{@prefs.cdrom} -A --no-cddb")

    if isValidQuery(query)
      @status = 'ok'
      parseQuery(query)
      addExtraInfo()
    end
  end

  # return the startsector for a track
  def getStartSector(tracknumber) ; @startSector[tracknumber] ; end

  # return the length for a track (in sectors)
  def getLengthSector(tracknumber) ; @lengthSector[tracknumber] ; end

  # return the length for a track (in mm:ss.ff)
  def getLengthText(tracknumber) ; @lengthText[tracknumber] ; end

  def tracks ; @audiotracks + @dataTracks.length ; end

private

  # check the query result for errors
  def isValidQuery(query)
    if query.nil?
      @status = 'notInstalled'
      return false
    end
    
    query.each do |line|
      case line
        when /WARN: Can't get file status/ then @status = 'unknownDrive' ; break
        when /Usage:/ then @status = 'wrongParameters' ; break
        when /WARN: error in ioctl/ then @status = 'noDiscInDrive' ; break
      end
    end

    return @status.nil?
  end

  # store the info of the query in variables
  def parseQuery(query)
    tracknumber = 0
    query.each do |line|
      @version = line.strip() if line =~ /cd-info version/
      @vendor = $'.strip if line =~ /Vendor\s+:\s/
      @model = $'.strip if line =~ /Model\s+:\s/
      @revision = $'.strip if line =~ /Revision\s+:\s/
      @discMode = $'.strip if line =~ /Disc mode is listed as:\s/

      # discover a track
      if line =~ /\s+\d+:\s/ # for example: '  1: '
        tracknumber = $&.strip()[0..-2].to_i
        trackinfo = $'.split(/\s+/)
        @startSector[tracknumber] = toSectors(trackinfo[0]) + OFFSET_CDINFO
        @dataTracks << tracknumber if trackinfo[2] == "data"
        @firstAudioTrack = tracknumber unless @firstAudioTrack || trackinfo[2] == "data"
      end

      if line =~ /leadout/
        line =~ /\d\d:\d\d:\d\d/
        @totalSectors = toSectors($&) + OFFSET_CDINFO
        break
      end
    end
    @finalTrack = tracknumber
  end

  # Add some extra info that is calculated
  def addExtraInfo
    @deviceName = "#{@vendor} #{@model} #{@revision}"
    @playtime = toTime(@totalSectors)[0,5]
    @audiotracks = @startSector.length - @dataTracks.length

    @lengthSector = Hash.new
    @lengthText = Hash.new
    @startSector.each do |tracknumber, value|
      if tracknumber == @finalTrack
        @lengthSector[tracknumber] = @totalSectors - @startSector[tracknumber]
      else
        @lengthSector[tracknumber] = @startSector[tracknumber + 1] - value
      end
      @lengthText[tracknumber] = toTime(@lengthSector[tracknumber])
    end
  end
end
