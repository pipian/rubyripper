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
  end

  def show
    showVersion()
    showRippingPrefs()
    showEncodingPrefs()
    showDiscInfo()
    showLaunch()
  end

private

  def showVersion
    @log << _("This log is created by Rubyripper, version %s\n") % [$rr_version]
    @log << _("Website: http://code.google.com/p/rubyripper\n\n")
  end

  def showRippingPrefs
    @log << _("Cdrom player used to rip:\n%s\n") % [@disc.devicename]
    @log << _("Cdrom offset used: %s\n\n") % [@prefs.offset]
    @log << _("Ripper used: cdparanoia %s\n") % [@prefs.rippersettings]
    @log << _("Matches required for all chunks: %s\n") % [@prefs.reqMatchesAll]
    @log << _("Matches required for erroneous chunks: %s\n\n") % [@prefs.reqMatchesErrors]
  end

  def showEncodingPrefs
    @log << _("Codec(s) used:\n")
    @log << _("-flac \t-> %s (%s)\n") % [@prefs.settingsFlac, version('flac')] if @prefs.flac
    @log << _("-vorbis\t-> %s (%s)\n") % [@prefs.settingsVorbis, version('oggenc')] if @prefs.vorbis
    @log << _("-mp3\t-> %s\n(%s\n") % [@prefs.settingsMp3, version('lame')] if @prefs.mp3
    @log << _("-wav\n") if @prefs.wav
    @log << _("-other\t-> %s\n") % [@prefs.settingsOther] if @prefs.other
  end

  def version(name)
    `#{name} --version`.split("\n")[0].strip()
  end

  def showDiscInfo
    @log << _("\nDISC INFO\n")
    @log << "\n" + _('Artist') + "\t= %s" % [@md.artist]
    @log << "\n" + _('Album') + "\t= %s" % [@md.album]
    @log << "\n" + _("Year") + "\t= %s" % [@md.year]
    @log << "\n" + _("Genre") + "\t= %s" % [@md.genre]
    @log << "\n" + _("Tracks") + "\t= %s (%s selected)\n\n" % [@disc.audiotracks, @tracks]

    (1..@disc.audiotracks).each do |track|
      @log << "#{sprintf("%02d", track)} - #{@md.trackname(track)}\n"
    end
  end

  def showLaunch
    @log << "\n" + _("STATUS") + "\n\n"
  end
end