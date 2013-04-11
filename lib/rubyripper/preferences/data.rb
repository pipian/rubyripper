#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2013  Bouke Woudstra (boukewoudstra@gmail.com)
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

#The Data class stores all preferences
module Preferences
  class Data

    def allCodecs
      ['flac', 'mp3', 'vorbis', 'wav', 'nero', 'fraunhofer', 'wavpack', 'opus', 'other']
    end

    def codecs
      @codecs ||= setActiveCodecs()
    end

    # return all active codecs in an array
    def setActiveCodecs
      @codecs = Array.new
      allCodecs.each{|codec| @codecs << codec if self.send(codec)}
      @codecs
    end

    # RIPPING PREFERENCES
    # The location of the drive that does the ripping
    attr_accessor :cdrom

    # The offset for the drive
    attr_accessor :offset

    # If true, pad missing samples (due to the offset) with zeroes.
    attr_accessor :padMissingSamples

    # Extra parameters passed to cdparanoia
    attr_accessor :rippersettings

    # The amount of times all sectors have to match
    attr_accessor :reqMatchesAll

    # The amount of times bad sectors have to match
    attr_accessor :reqMatchesErrors

    # The amount of tries before giving up
    attr_accessor :maxTries

    # Open up the tray when finished
    attr_accessor :eject

    # Throw away the log if no errors are found
    attr_accessor :noLog

    # TOC ANALYSIS PREFERENCES
    # Create a cuesheet
    attr_accessor :createCue

    # Rip to a single file
    attr_accessor :image

    # Rip hidden audio sectors
    attr_accessor :ripHiddenAudio

    # Minimum seconds to be marked as hidden track
    attr_accessor :minLengthHiddenTrack

    # Append or prepend hidden audio sectors: 'prepend' || 'append'
    attr_accessor :preGaps

    # How to handle pre-emphasis 'sox' || 'cue'
    attr_accessor :preEmphasis

    # CODEC PREFERENCES
    # Use flac
    attr_accessor :flac

    # Pass flac parameters
    attr_accessor :settingsFlac

    # Use vorbis
    attr_accessor :vorbis

    # Pass vorbis parameters
    attr_accessor :settingsVorbis

    # Use mp3
    attr_accessor :mp3

    # Pass lame parameters
    attr_accessor :settingsMp3

    # Use wav
    attr_accessor :wav

    # Use wav parameters (only there to be consistent)
    attr_accessor :settingsWav

    # Use Nero AAC
    attr_accessor :nero

    # Pass nero parameters
    attr_accessor :settingsNero

    # Use Fraunhofer AAC (fdkaac)
    attr_accessor :fraunhofer

    # Pass fraunhofer parameters
    attr_accessor :settingsFraunhofer

    # Use Wavpack
    attr_accessor :wavpack

    # Pass wavpack parameters
    attr_accessor :settingsWavpack

    # Use Opus
    attr_accessor :opus

    # Pass Opus parameters
    attr_accessor :settingsOpus

    # Use other codec
    attr_accessor :other

    # Pass other codec command
    attr_accessor :settingsOther

    # Make a m3u playlist
    attr_accessor :playlist

    # Maximum amount of extra encoding threads
    attr_accessor :maxThreads

    # Replace spaces with underscores
    attr_accessor :noSpaces

    # Downsize all capital letters in filenames
    attr_accessor :noCapitals

    # Normalize program: 'none'|| 'normalize' || 'replaygain'
    attr_accessor :normalizer

    # Normalize modus 'album' || 'track'
    attr_accessor :gain

    # METADATA PREFERENCES
    # Choose metadata provider 'none' || 'freedb' || 'musicbrainz' 
    attr_accessor :metadataProvider

    # Always use first hit from freedb
    attr_accessor :firstHit

    # Freedb server used
    attr_accessor :site

    # Freedb username for authentication
    attr_accessor :username

    # Freedb hostname for authentication
    attr_accessor :hostname

    # MUSICBRAINZ PREFERENCES
    # Order of countries from which releases are preferred (from best
    # to worst; anything not in the list is preferred equally less than
    # anything in the list) Use the two-letter country format.
    # for example: US,UK,XW,XE,JP
    attr_accessor :preferMusicBrainzCountries

    # Preferred release dates: 'earlier' || 'later' || 'no' (don't prefer by dates at all)
    attr_accessor :preferMusicBrainzDate

    # Use the earliest release date in the release-group to set the
    # year, rather than the date of the selected release (i.e. prefer
    # LP release dates to CD release dates)
    attr_accessor :useEarliestDate

    # OTHER PREFERENCES
    # Base output directory for all your rips
    attr_accessor :basedir

    # Standard filescheme
    attr_accessor :namingNormal

    # Various filescheme
    attr_accessor :namingVarious

    # Singe file rip filescheme
    attr_accessor :namingImage

    # Log file viewer
    attr_accessor :editor

    # File manager
    attr_accessor :filemanager

    # Browser
    attr_accessor :browser

    # Verbose modus
    attr_accessor :verbose

    # Debug modus
    attr_accessor :debug

    # TEST DATA
    attr_accessor :testdisc
  end
end
