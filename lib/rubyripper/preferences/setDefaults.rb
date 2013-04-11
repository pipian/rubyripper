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

require 'rubyripper/preferences/main'
require 'rubyripper/system/dependency'

module Preferences
  class SetDefaults
    def initialize(deps=nil, prefs=nil)
      @data = prefs ? prefs.data : Preferences::Main.instance.data
      @deps = deps ? deps : Dependency.instance
      setDefaults()
    end

    def setDefaults()
      setRippingDefaults()
      setTocAnalysisDefaults()
      setCodecDefaults()
      setFreedbDefaults()
      setMusicBrainzDefaults()
      setOtherDefaults()
    end

    def setRippingDefaults
      @data.cdrom = @deps.cdrom()
      @data.offset = 0
      @data.padMissingSamples = true
      @data.rippersettings = '-Z'
      @data.reqMatchesAll = 2
      @data.reqMatchesErrors = 3
      @data.maxTries = 7
      @data.eject = true
      @data.noLog = false
    end

    def setTocAnalysisDefaults
      @data.createCue = true
      @data.image = false
      @data.ripHiddenAudio = true
      @data.minLengthHiddenTrack = 6
      @data.preGaps = 'append' # see issue 527
      @data.preEmphasis = 'cue'
    end

    def setCodecDefaults
      @data.flac = false
      @data.settingsFlac = '--best -V'
      @data.vorbis = true
      @data.settingsVorbis = '-q 4'
      @data.mp3 = false
      @data.settingsMp3 = '-V 3 --id3v2-only'
      @data.nero = false
      @data.settingsNero = '-q 0.5'
      @data.fraunhofer = false
      @data.settingsFraunhofer = '-p 2 -m 5 -a 1'
      @data.wavpack = false
      @data.settingsWavpack = ''
      @data.opus = false
      @data.settingsOpus = '--bitrate 160'
      @data.wav = false
      @data.other = false
      @data.settingsOther = 'flac %i %o.flac'
      @data.playlist = true
      @data.maxThreads = 2
      @data.noSpaces = false
      @data.noCapitals = false
      @data.normalizer = 'none'
      @data.gain = 'album'
    end

    def setFreedbDefaults
      @data.metadataProvider = 'freedb'
      @data.firstHit = true
      @data.site = 'http://freedb.freedb.org/~cddb/cddb.cgi'
      @data.username = 'anonymous'
      @data.hostname = 'my_secret.com'
    end

    def setMusicBrainzDefaults
      @data.preferMusicBrainzCountries = 'US,UK,XW,XE,JP'
      @data.preferMusicBrainzDate = 'earlier'
      @data.useEarliestDate = true
    end

    def setOtherDefaults
      @data.basedir = '~/'
      @data.namingNormal = '%f/%a (%y) %b/%n - %t'
      @data.namingVarious = '%f/%va (%y) %b/%n - %a - %t'
      @data.namingImage = '%f/%a (%y) %b/%a - %b (%y)'
      @data.editor = @deps.editor()
      @data.filemanager = @deps.filemanager
      @data.browser = @deps.browser
      @data.verbose = false
      @data.debug = false
    end
  end
end
