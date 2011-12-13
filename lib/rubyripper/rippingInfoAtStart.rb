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
require 'rubyripper/system/execute.rb'

class RippingInfoAtStart
  def initialize(disc, log, trackSelection, prefs=nil, execute=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @disc = disc
    @log = log
    @tracks = trackSelection.length
    @md = disc.metadata
    @execute = execute ? execute : Execute.new()
  end

  def show
    showVersion()
    showBasicRipInfo()
    showRippingPrefs()
    showEncodingPrefs()
    showDiscInfo()
    showLaunch()
  end

private

  def showVersion
    @log << _("Rubyripper v%s\n") % [$rr_version]
    @log << _("Website: http://code.google.com/p/rubyripper\n\n")
  end

  def showBasicRipInfo
    @log << _("Rubyripper extraction logfile from %s\n\n") % [Time.now.strftime("%a %b %d %H:%M:%S %Z %Y")]
    @log << "%s / %s\n\n" % [@md.artist, @md.album]
  end

  def showRippingPrefs
    @log << _("Used drive     : %s   Device: %s\n\n") % [@disc.devicename, @prefs.cdrom]
    
    @log << _("Used ripper    : %s\n") % [version('cdparanoia')]
    @log << _("Selected flags : %s\n\n") % [@prefs.rippersettings]
    
    @log << _("Matches required for all chunks       : %s\n") % [@prefs.reqMatchesAll]
    @log << _("Matches required for erroneous chunks : %s\n\n") % [@prefs.reqMatchesErrors]

    @log << _("Read offset correction                      : %s\n") % [@prefs.offset]
    @log << _("Overread into Lead-In and Lead-Out          : No\n")
    @log << _("Fill up missing offset samples with silence : %s\n") % [@prefs.padMissingSamples ? _("Yes") : _("No")]
    @log << _("Null samples used in CRC calculations       : Yes\n\n")
  end

  def showEncodingPrefs
    if @prefs.flac
      @log << _("Used output encoder : %s\n") % [version('flac')]
      @log << _("Selected flags      : %s\n\n") % [@prefs.settingsFlac]
    end
    if @prefs.vorbis
      @log << _("Used output encoder : %s\n") % [version('oggenc')]
      @log << _("Selected flags      : %s\n\n") % [@prefs.settingsVorbis]
    end
    if @prefs.mp3
      @log << _("Used output encoder : %s\n") % [version('lame')]
      @log << _("Selected flags      : %s\n\n") % [@prefs.settingsMp3]
    end
    if @prefs.wav
      @log << _("Used output encoder : %s\n") % [_("Internal WAV Routines")]
      @log << _("Sample format       : 44,100 Hz; 16 Bit; Stereo\n\n")
    end
    if @prefs.other
      @log << _("Used output encoder : %s\n") % [_("User Defined Encoder")]
      @log << _("Command line        : %s\n\n") % [@prefs.settingsOther]
    end
  end

  def version(name)
    @execute.launch("#{name} --version")[0].strip()
  end

  def showDiscInfo
    @log << _("TOC of the extracted CD\n\n")
    
    @log << _("     Track |   Start  |  Length  | Start sector | End sector \n")
    @log << _("    ---------------------------------------------------------\n")
    # KLUDGE: Temporarily toggle @prefs.image off to get the right sectors
    old_image = @prefs.image
    @prefs.image = false
    (1..@disc.audiotracks).each do |track|
      # TODO: Needs start sector of data tracks too.
      start = @disc.getStartSector(track)
      start_min = start / 75 / 60
      start_sec = start / 75 % 60
      start_frm = start % 60
      
      length = @disc.getLengthSector(track)
      length_min = length / 75 / 60
      length_sec = length / 75 % 60
      length_frm = length % 60
      
      @log << _("       %2d  | %2d:%02d.%02d | %2d:%02d.%02d |    %6d    |   %6d   \n") % [track, start_min, start_sec, start_frm, length_min, length_sec, length_frm, start, start + length - 1]
    end
    @prefs.image = old_image
    @log << "\n"
  end

  def showLaunch
    @log << "\n"
  end
end
