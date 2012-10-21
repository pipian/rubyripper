#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012  Bouke Woudstra (boukewoudstra@gmail.com)
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
#
# NOTE Currently Data tracks are totally ignored for the cuesheet.
#
# The Cuesheet class is there to provide a Cuesheet.
# A cuesheet contains all necessary info to exactly reproduce
# the structure of a disc. It is used by advanced burning programs.
# The assumption is made that all tracks are ripped, why else would
# you need a cuesheet?

require 'rubyripper/system/fileAndDir'
require 'rubyripper/preferences/main'
require 'rubyripper/system/dependency'

class Cuesheet
  
  FRAMES_A_SECOND = 75
  FRAMES_A_MINUTE = 60 * FRAMES_A_SECOND
  HIDDEN_FIRST_TRACK = 0
  FIRST_TRACK = 1
  
  attr_reader :cuesheet
  
  def initialize(disc, cdrdao, fileScheme, fileAndDir=nil, prefs=nil, deps=nil)
    @disc = disc
    @cdrdao = cdrdao
    @fileScheme = fileScheme
    @fileAndDir = fileAndDir ? fileAndDir : FileAndDir.instance
    @prefs = prefs ? prefs : Preferences::Main.instance()
    @deps = deps ? deps : Dependency.instance()
    @md = @disc.metadata
    @cuesheet = Array.new # for testing purposes
  end

  # return an array with the cuesheet for a codec
  def save(codec)
    @cuesheet = Array.new
    printDiscData
    @prefs.image ? printTrackDataImage(codec) : printTrackData(codec)
    @cuesheet
  end

  # for testing purposes
  def test_printDiscData ; printDiscData() ; end
  def test_printTrackDataImage(codec) ; printTrackDataImage(codec) ; end
  def test_printTrackData(codec) ; printTrackData(codec) ; end 
   
private

  def getCueFileType(codec)
    codec == 'mp3' ? 'MP3' : 'WAVE' 
  end

  def time(sector) # minutes:seconds:leftover frames
    minutes = sector / FRAMES_A_MINUTE 
    seconds = (sector % FRAMES_A_MINUTE) / FRAMES_A_SECOND
    frames = sector % FRAMES_A_SECOND
    return "#{sprintf("%02d", minutes)}:#{sprintf("%02d", seconds)}:#{sprintf("%02d", frames)}"
  end

  def printDiscData
    @cuesheet << "REM GENRE #{@md.genre}"
    @cuesheet << "REM DATE #{@md.year}"
    @cuesheet << "REM DISCID #{@disc.freedbDiscid}"
    @cuesheet << "REM FREEDB_QUERY \"#{@disc.freedbString}\""
    @cuesheet << "REM COMMENT \"Rubyripper #{$rr_version}\""
    @cuesheet << "PERFORMER \"#{@md.artist}\""
    @cuesheet << "TITLE \"#{@md.album}\""
  end
  
  # The trackinfo for an image rip is relatively simple, since we don't have to account
  # for the prepend / append preference since it's not relevant for image rips.
  def printTrackDataImage(codec)
    printFileLine(codec)
    (1..@disc.audiotracks).each  do |track|
      printTrackLine(track)
      printTrackMetadata(track)
      if track == FIRST_TRACK
        printPregapForHiddenTrack()
        printIndexFirstTrack()
      else
        printIndexImageOtherTracks(track)
      end
    end
  end

   #writes the location of the file in the Cue
  def printFileLine(codec, track=nil)
    @cuesheet << "FILE \"#{File.basename(@fileScheme.getFile(codec, track))}\" #{getCueFileType(codec)}"
  end
  
  def printTrackLine(track)
    @cuesheet << "  TRACK #{sprintf("%02d", track)} AUDIO"
  end

  # write the info for a single track
  def printTrackMetadata(track)
    @cuesheet << "    TITLE \"#{@md.trackname(track)}\""
    @cuesheet << "    PERFORMER \"#{@md.various? ? @md.getVarArtist(track) : @md.artist}\""
  end
  
  # print a line for the index of a track
  def printIndexLine(index, sector)
    @cuesheet << "    INDEX #{index} #{time(sector)}"
  end

  def aHiddenTrackIsRipped
    hiddenSectorsInMinutes = @disc.getStartSector(FIRST_TRACK) / FRAMES_A_SECOND
    @prefs.image == false && @prefs.ripHiddenAudio == true && hiddenSectorsInMinutes >= @prefs.minLengthHiddenTrack
  end
  
  # if the hidden audio is not prepended to the file, only write a pregap tag
  def printPregapForHiddenTrack
    if (@prefs.ripHiddenAudio == false || aHiddenTrackIsRipped()) &&
        @disc.getStartSector(FIRST_TRACK) > 0
      @cuesheet << "    PREGAP #{time(@disc.getStartSector(FIRST_TRACK))}"
    end
  end

  # If there are sectors before track 1, print an index 00 for sector 0
  def printIndexFirstTrack()
    if @prefs.ripHiddenAudio == true && @disc.getStartSector(FIRST_TRACK) > 0 && !aHiddenTrackIsRipped()
      printIndexLine('00', 0)
      printIndexLine('01', @disc.getStartSector(FIRST_TRACK))
    else
      printIndexLine('01', 0)
    end
  end

  def printIndexImageOtherTracks(track)
    if @cdrdao.getPregapSectors(track) > 0
      printIndexLine('00', @disc.getStartSector(track))
      printIndexLine('01', @disc.getStartSector(track) + @cdrdao.getPregapSectors(track))
    else # no pregap
      printIndexLine('01', @disc.getStartSector(track))
    end
  end
  
  # Start the logic for rips that are based on track ripping
  def printTrackData(codec)
    (1..@disc.audiotracks).each do |track|
      @prefs.preGaps == 'prepend' ? printFileLine(codec, track) : printFileLineAppend(codec, track)
      printTrackLine(track)
      printTrackMetadata(track)
      printFlags(track)
      if track == FIRST_TRACK
        printPregapForHiddenTrack()
        printIndexFirstTrack()
      else
        @prefs.preGaps == 'prepend' ? printIndexOtherTracks(track) : printIndexOtherTracksAppend(track)
      end
    end
  end

  def printFlags(track)
    if @cdrdao.preEmph?(track) && @prefs.preEmphasis == 'cue'
      @cuesheet << '    FLAGS PRE'
    end
  end
  
  def printIndexOtherTracks(track)
    if @cdrdao.getPregapSectors(track) == 0
      printIndexLine('01', 0)
    else
      printIndexLine('00', 0)
      printIndexLine('01', @cdrdao.getPregapSectors(track))
    end
  end

  # if gaps, print the file line + 01 index at start of next track
  # else just write the fileline like the prepend modus at current track.
  def printFileLineAppend(codec, track)
    if @cdrdao.getPregapSectors(track) != 0
      printFileLine(codec, track - 1)
      printIndexLine('01', 0)
    end

    if @cdrdao.getPregapSectors(track + 1) == 0
      printFileLine(codec, track)
    end
  end
  
  # if no gaps next track, just write 01 index
  # else write a zero index at the end of the file
  def printIndexOtherTracksAppend(track)
    if @cdrdao.getPregapSectors(track + 1) == 0
      printIndexLine('01', 0)
    else
      printIndexLine('00', @disc.getLengthSector(track) - @cdrdao.getPregapSectors(track + 1))
    end
  end 
end