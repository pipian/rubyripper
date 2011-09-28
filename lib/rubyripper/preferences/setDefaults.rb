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

require 'rubyripper/system/dependency'

module Preferences
  class SetDefaults
    def initialize(main, deps=nil)
      @data = main.data
      @deps = deps ? deps : Dependency.new
      setDefaults()
    end

    def setDefaults()
      setRippingDefaults()
      setTocAnalysisDefaults()
      setCodecDefaults()
      setFreedbDefaults()
      setOtherDefaults()
      setTestingDefaults() unless $TST_DEFAULT_PREFS.nil?
    end

    def setRippingDefaults
      @data.cdrom = @deps.cdrom()
      @data.offset = 0
      @data.rippersettings = '-Z'
      @data.reqMatchesAll = 2
      @data.reqMatchesErrors = 3
      @data.maxTries = 5
      @data.eject = true
      @data.noLog = false
    end

    def setTocAnalysisDefaults
      @data.createCue = true
      @data.image = false
      @data.ripHiddenAudio = true
      @data.minLengthHiddenTrack = 2
      @data.preGaps = 'prepend'
      @data.preEmphasis = 'cue'
    end

    def setCodecDefaults
      @data.flac = false
      @data.settingsFlac = '--best -V'
      @data.vorbis = true
      @data.settingsVorbis = '-q 4'
      @data.mp3 = false
      @data.settingsMp3 = '-V 3 --id3v2-only'
      @data.wav = false
      @data.other = false
      @data.settingsOther = String.new
      @data.playlist = true
      @data.maxThreads = 2
      @data.noSpaces = false
      @data.noCapitals = false
      @data.normalizer = 'none'
      @data.gain = 'album'
      @data.gainTagsOnly = false
    end

    def setFreedbDefaults
      @data.freedb = true
      @data.firstHit = true
      @data.site = 'http://freedb.freedb.org/~cddb/cddb.cgi'
      @data.username = 'anonymous'
      @data.hostname = 'my_secret.com'
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

    # override some settings for testing to be predictable
    def setTestingDefaults
      @data.cdrom = '/dev/cdrom'
      @data.editor = 'mousepad'
      @data.filemanager = 'thunar'
      @data.browser = 'firefox'
      @data.basedir = '/home/test'
    end
  end
end
