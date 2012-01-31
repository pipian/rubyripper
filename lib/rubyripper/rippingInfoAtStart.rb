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

require 'rubyripper/preferences/main'

class RippingInfoAtStart
  def initialize(disc, log, trackSelection, prefs=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @disc = disc
    @log = log
    @tracks = trackSelection.length
    @md = disc.metadata
    @logString = String.new
  end

  def show
    showVersion()
    showRippingPrefs()
    showEncodingPrefs()
    showDiscInfo()
    showLaunch()
    updateInterface()
  end

private

  def showVersion
    @logString << _("This log is created by Rubyripper, version %s\n") % [$rr_version]
    @logString << _("Website: http://code.google.com/p/rubyripper\n\n")
  end

  def showRippingPrefs
    @logString << _("Cdrom player used to rip:\n%s\n") % [@disc.devicename]
    @logString << _("Cdrom offset used: %s\n\n") % [@prefs.offset]
    @logString << _("Ripper used: cdparanoia %s\n") % [@prefs.rippersettings]
    @logString << _("Matches required for all chunks: %s\n") % [@prefs.reqMatchesAll]
    @logString << _("Matches required for erroneous chunks: %s\n\n") % [@prefs.reqMatchesErrors]
  end

  def showEncodingPrefs
    @logString << _("Codec(s) used:\n")
    @logString << _("-flac \t-> %s (%s)\n") % [@prefs.settingsFlac, version('flac')] if @prefs.flac
    @logString << _("-vorbis\t-> %s (%s)\n") % [@prefs.settingsVorbis, version('oggenc')] if @prefs.vorbis
    @logString << _("-mp3\t-> %s\n(%s\n") % [@prefs.settingsMp3, version('lame')] if @prefs.mp3
    @logString << _("-wav\n") if @prefs.wav
    @logString << _("-other\t-> %s\n") % [@prefs.settingsOther] if @prefs.other
  end

  def version(name)
    `#{name} --version`.split("\n")[0].strip()
  end

  def showDiscInfo
    @logString << _("\nDISC INFO\n")
    @logString << "\n" + _('Artist') + "\t= %s" % [@md.artist]
    @logString << "\n" + _('Album') + "\t= %s" % [@md.album]
    @logString << "\n" + _("Year") + "\t= %s" % [@md.year]
    @logString << "\n" + _("Genre") + "\t= %s" % [@md.genre]
    @logString << "\n" + _("Tracks") + "\t= %s (%s selected)\n\n" % [@disc.audiotracks, @tracks]

    (1..@disc.audiotracks).each do |track|
      @logString << "#{sprintf("%02d", track)} - #{@md.trackname(track)}\n"
    end
  end

  def showLaunch
    @logString << "\n" + _("STATUS") + "\n\n"
  end
  
  def updateInterface
    @log << @logString
    @logString = nil
  end
end