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

# WILL OBSOLETE handlePrefs.rb
#The Data class stores all preferences
module Preferences
  class Data
    # RIPPING PREFERENCES
    # The location of the drive that does the ripping
    attr_accessor :cdrom

    # The offset for the drive
    attr_accessor :offset

    #* Extra parameters passed to cdparanoia
    attr_accessor :ripperSettings

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

    # Append or prepend hidden audio sectors
    attr_accessor :preGaps

    # How to handle pre-emphasis
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

    # Normalize program
    attr_accessor :normalizer

    # Normalize modus
    attr_accessor :gain

    # Set the gain in the tags only
    attr_accessor :gainTagsOnly

    # FREEDB PREFERENCES
    # Fetch metadata for the disc with freedb
    attr_accessor :freedb

    # Always use first hit from freedb
    attr_accessor :firstHit

    # Freedb server used
    attr_accessor :site

    # Freedb username for authentication
    attr_accessor :username

    # Freedb hostname for authentication
    attr_accessor :hostname

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

    # Verbose modus
    attr_accessor :verbose

    # Debug modus
    attr_accessor :debug
  end
end