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

# A class that interprets the toc with the info of cdparanoia
# It's purpose is pure for ripping the correct audio, not for
# creating the freedb string. Cd-info is better for that.
# Before ripping, the function checkOffsetFirstTrack should be called.
class ScanDiscCdparanoia
  attr_reader :status, :playtime, :audiotracks, :devicename, :firstAudioTrack,
      :totalSectors, :error, :multipleDriveSupport

  # * preferences is an instance of Preferences
  # * fireCommand is an instance of FireCommand
  # * permissionDrive is an instance of PermissionDrive
  def initialize(fireCommand, permissionDrive, preferences, out=nil)
    @fire = fireCommand
    @perm = permissionDrive
    @prefs = preferences
    @out = out ? out : $stdout
  end

  # scan the disc for input and return the object
  def scan ; waitForDisc() ; end

  # return the startSector, example for track 1 getStartSector(1)
  # if image, return the start sector for the lowest tracknumber
  def getStartSector(track)
    assertDiscFound('getStartSector')
    case track
      when 'image' then @startSector[@startSector.keys.sort[0]]
      else @startSector[track]
    end
  end

  # return the sectors, example for track 1 getLengthSector(1)
  def getLengthSector(track)
    assertDiscFound('getLengthSector')
    case track
      when 'image' then @totalSectors
      else @lengthSector[track]
    end
  end

  # return the length in text, example for track 1 getLengthSector(1)
  def getLengthText(track)
    assertDiscFound('getLengthText')
    case track
      when 'image' then @playtime
      else @lengthText[track]
    end
  end

  # return the length in bytes, example for track 1 getFileSize(1)
  def getFileSize(track)
    assertDiscFound('getFileSize')
    case track
      when 'image' then 44 + @totalSectors * 2352
      else (44 + @lengthSector[track] * 2352) if @lengthSector.key?(track)
    end
  end

  def tracks ; return @audiotracks ; end

  # prepend the gaps, so rewrite the toc info
  # notice that cdparanoia appends by default
  # * scanCdrdao = instance of ScanDiscCdrdao
#   def prependGaps(scanCdrdao)
#     assertDiscFound('prependGaps')
#     (2..@audiotracks).each do |track|
#       pregap = scanCdrdao.getPregap(track)
#       @lengthSector[track - 1] -= pregap
#       @startSector[track] -= pregap
#       @lengthSector[track] += pregap
#     end
#   end

  private

  def setError(code, parameters=nil)
    @status = 'error'
    @error = [code, parameters]
  end

  # new scan, new chances, so reset the error status
  def unsetError
    @status = nil
    @error = nil
  end

  # verify a disc is found
  def assertDiscFound(name)
    raise "Can't #{name} when scanDiscCdparanoia status is not ok!" unless @status == 'ok'
  end

  # give the cdrom drive a few seconds to read the disc
  def waitForDisc
    (1..10).each do |trial|
      unsetError()
      readDisc()
      break if @status == 'ok' || $test
      @out.puts _("No disc found at trial %s!") % [trial]
      sleep(1)
    end
  end

  def readDisc
    query = getQueryResult()
    parseQueryResult(query)
  end

  def getQueryResult
    if $TST_DISC_PARANOIA != nil
      query = $TST_DISC_PARANOIA
    else
      @multipleDriveSupport = true
      query = @fire.launch("cdparanoia -d #{@prefs.cdrom} -vQ 2>&1")
      # some versions of cdparanoia don't support the cdrom parameter
      if query.include?('USAGE')
        query = @fire.launch("cdparanoia -vQ 2>&1")
        @multipleDriveSupport = false
      end
    end
    return query
  end

  def parseQueryResult(query)
    if isValidQuery(query)
      parseQuery(query)
      addExtraInfo()
      checkOffsetFirstTrack()
      if $TST_DISC_PARANOIA.nil?
        @status = @perm.check(@prefs.cdrom, query)
      else
        @status = 'ok'
      end
    end
  end

  # check the query result for errors
  def isValidQuery(query)
    case query
      when /Unable to open disc/ then setError(:noDiscInDrive, @prefs.cdrom)
      when /USAGE/ then setError(:wrongParameters, 'Cdparanoia')
      when /No such file or directory/ then setError(:unknownDrive, @prefs.cdrom)
    end

    return @error.nil?
  end

  def setupDisc
    @startSector = Hash.new
    @lengthSector = Hash.new
    @lengthText = Hash.new
    @dataTracks = Array.new
  end

  # store the variables of the line
  def addTrack(line, currentTrack)
    tracknumber, lengthSector, lengthText, startSector = line.split

    @firstAudioTrack = tracknumber[0..-2].to_i if currentTrack == 1
    @lengthSector[currentTrack] = lengthSector.to_i
    @startSector[currentTrack] = startSector.to_i
    @lengthText[currentTrack] = lengthText[1..-5]
  end

  # store the info of the query in variables
  def parseQuery(query)
    setupDisc()
    currentTrack = 0
    query.each_line do |line|
      if line[0,5] =~ /\s+\d+\./
        currentTrack += 1
        addTrack(line, currentTrack)
      elsif line =~ /CDROM\D*:/
        @devicename = $'.strip()
      elsif line[0,5] == "TOTAL"
        @playtime = line.split()[2][1,5]
      end
    end
    @audiotracks = currentTrack
  end

  # add some extra variables
  def addExtraInfo
    @status = _('ERROR: No audio tracks found!') if @audioTracks == 0

    @totalSectors = 0
    @lengthSector.each_value{|value| @totalSectors += value}
  end

  # When a data track is the first track on a disc, cdparanoia is acting
  # strange: In the query it is showing as a start for 1s track the offset of
  # the data track. When ripping this offset isn't used however !! To allow
  # a correct rip of this disc all startSectors have to be corrected. See
  # also issue 196.

  # If there is no data track at the start, but we do have an offset this
  # means some hidden audio part. This part is marked as track 0. You can
  # only assess this on a cd-player by rewinding from 1st track on.
  def checkOffsetFirstTrack()
    # correct the startSectors when a disc starts with data
    if @firstAudioTrack != 1
      dataOffset = @startSector[1]
      @startSector.each_key{|key| @startSector[key] -= dataOffset}
      #do nothing extra when hidden audio shouldn't be ripped
      #in the cuesheet this part will be marked as a pregap (silence).
    elsif @prefs.ripHiddenAudio == false
      # if size of hiddenAudio is bigger than minimum length, make track 0
    elsif (@startSector[1] != 0 && @startSector[1] / 75.0 > @prefs.minLengthHiddenTrack)
      @startSector[0] = 0
      @lengthSector[0] = @startSector[1]
      # otherwise prepend it to the first track
    elsif @startSector[1] != 0
      @lengthSector[1] += @startSector[1]
      @startSector[1] = 0
    end
  end
end
