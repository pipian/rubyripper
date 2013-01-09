#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2011  Ian Jacobi (pipian@pipian.com)
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

require 'rubyripper/preferences/main'
require 'rubyripper/system/execute'
require 'rubyripper/modules/audioCalculations'

# A class that interprets the toc with the info of cdcontrol (from
# FreeBSD) Quite reliable for detecting data tracks and can even
# automatically generate freedb strings.  Doesn't support :deviceName.
# Notice that cdparanoia and cdcontrol might have conflicting results for
# discs with data tracks. For freedb calculation cdcontrol is correct, for
# detecting the audio part, cdparanoia is correct.
class ScanDiscCdcontrol
  include AudioCalculations
  
  attr_reader :status, :totalSectors, :playtime, :audiotracks,
      :firstAudioTrack, :dataTracks

  # * cdrom = a string with the location of the drive
  # * testRead = a string with output of cdcontrol for unit testing purposes
  def initialize(execute=nil, prefs=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @exec = execute ? execute : Execute.new()

    @startSector = Hash.new
    @dataTracks = Array.new
  end

  # scan the contents of the disc
  def scan
    return true if @status == 'ok'
    query = @exec.launch("cdcontrol -f #{@prefs.cdrom} info")

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
        when /No such file or directory/ then @status = 'unknownDrive' ; break
        when /cdcontrol: invalid command/ then @status = 'wrongParameters' ; break
        when /Device not configured/ then @status = 'noDiscInDrive' ; break
      end
    end

    return @status.nil?
  end

  # store the info of the query in variables
  def parseQuery(query)
    tracknumber = 0
    query.each do |line|
      # discover a track
      if line =~ /^\s+\d+\s+/ # for example: '  1 '
        tracknumber = $&.strip().to_i
        trackinfo = $'.split(/\s+/)
        if tracknumber == 170
          @totalSectors = trackinfo[2].to_i
        else
          @startSector[tracknumber] = trackinfo[2].to_i
          @dataTracks << tracknumber if trackinfo[4] == "data"
          @firstAudioTrack = tracknumber unless @firstAudioTrack || trackinfo[4] == "data"
          @finalTrack = tracknumber
        end
      end
    end
  end

  # Add some extra info that is calculated
  def addExtraInfo
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
