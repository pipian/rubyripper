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

# helper for interpreting commandline options
require 'optparse'
require 'rubyripper/preferences/main'
require 'rubyripper/cli/cliGetAnswer'

# CliPreferences is responsible for showing and editing the preferences
# It also interpretes the parameters when loaded
class CliPreferences

  def initialize(arguments, out=nil, int=nil, bool=nil, string=nil, prefs=nil)
    @options = arguments.options
    @out = out ? out : $stdout
    @int = int ? int : CliGetInt.new(@out)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @bool = bool ? bool : CliGetBool.new(@out)
    @string = string ? string : CliGetString.new(@out)
  end

  # Read the preferences
  def read ; readPreferences() ; end

  # return true if user has chosen for defaults
  def defaults ; return @options['defaults'] ; end

  # show the preferences menu
  def show ; loopMainMenu() ; end

private

  # Read the settings of the config file or the defaults
  def readPreferences()
    @prefs.load(@options['file'].to_s)
    @prefs.testdisc = @options['testdisc']

    if theFileFromUserDoesNotExist()
      @out.puts "WARNING: the provided configfile is not found."
      @out.puts "The default preferences are used instead."
    end

    loopMainMenu() if @options['configure']
  end

  # is the file provided by the user and does it not exist?
  def theFileFromUserDoesNotExist
    @options['file'].is_a?(String) && (@options['file'] != @prefs.filename)
  end

  # helper function to show boolean preference
  def showBool(bool)
    bool ? '[*]' : '[ ]'
  end

  # helper function to set boolean preference
  def switchBool(preference)
    newValue = !@prefs.send(preference)
    @prefs.send((preference + '=').to_sym, newValue)
  end

  # helper function to ask an option from multiple choices
  # choices is an array with possibilities
  # each choice is an array in its turn with ['preference', 'text shown to user']
  def multipleChoice(choices)
    @out.puts _("\nThere are #{choices.size} choices:\n")
    choices.each_index do |index|
      @out.puts " #{index+1}) #{choices[index][1]}"
    end

    choice = @int.get("\nWhich one do you prefer?", 1)

    if choice > choices.size
      noValidChoiceMessage(choice)
      multipleChoice(choices)
    else
      return choices[choice - 1][0]
    end
  end

  # show a menu for the different settings
  def showMainMenu
    @out.puts ""
    @out.puts _("** RUBYRIPPER PREFERENCES **")
    @out.puts ""
    @out.puts ' 1) ' + _('Secure ripping')
    @out.puts ' 2) ' + _('Toc analysis')
    @out.puts ' 3) ' + _('Codecs')
    @out.puts ' 4) ' + _('Metadata')
    @out.puts ' 5) ' + _('Other')
    @out.puts '99) ' + _("Don't change any setting")
    @out.puts ""
    @int.get("Please type the number of the setting you wish to change", 99)
  end

  # loop through the main menu
  def loopMainMenu
    case choice = showMainMenu()
      when 99 then @prefs.save() ; @out.puts '' # save the new settings to the configfile
      when 1 then loopSubMenuRipping()
      when 2 then loopSubMenuToc()
      when 3 then loopSubMenuCodecs()
      when 4 then loopSubMenuMetadata()
      when 5 then loopSubMenuOther()
    else
      noValidChoiceMessage(choice)
      loopMainMenu()
    end
  end

  def noValidChoiceMessage(choice)
    @out.puts _("Number #{choice} is not a valid choice, try again")
  end

  # show the ripping submenu
  def showSubMenuRipping
    @out.puts ''
    @out.puts _("*** SECURE RIPPING PREFERENCES ***")
    @out.puts ''
    @out.puts ' 1) ' + _("Ripping drive") + ": %s" %[@prefs.cdrom]
    @out.puts ' 2) ' + _("Drive offset") + ": %s" % [@prefs.offset]
    @out.puts _("    **Find your offset at http://www.accuraterip.com/driveoffsets.htm.")
    @out.puts _("    **Your drive model is shown in the logfile.")
    @out.puts ' 3) ' + _("Passing extra cdparanoia parameters") + ": %s" % [@prefs.rippersettings]
    @out.puts ' 4) ' + _("Match all chunks") + ": %s" % [@prefs.reqMatchesAll]
    @out.puts ' 5) ' + _("Match erroneous chunks") + ": %s" % [@prefs.reqMatchesErrors]
    @out.puts ' 6) ' + _("Maximum trials") + ": %s" % [@prefs.maxTries == 0 ? "no\
 maximum" : @prefs.maxTries]
    @out.puts ' 7) ' + _("Eject disc after ripping %s") % [showBool(@prefs.eject)]
    @out.puts ' 8) ' + _("Only keep log when errors %s") % [showBool(@prefs.noLog)]
    @out.puts '99) ' + _("Back to settings main menu")
    @out.puts ""
    @int.get("Please type the number of the setting you wish to change", 99)
  end

  # loop through the ripping submenu
  def loopSubMenuRipping
    case choice = showSubMenuRipping()
      when 99 then loopMainMenu()
      when 1 then @prefs.cdrom = @string.get(_("Ripping drive"),
        @prefs.cdrom)
      when 2 then @prefs.offset = @int.get(_("Drive offset"), 0)
      when 3 then @prefs.rippersettings = \
        @string.get(_("Passing extra cdparanoia parameters"), "")
      when 4 then @prefs.reqMatchesAll = @int.get(_("Match all chunks"), 2)
      when 5 then @prefs.reqMatchesErrors = @int.get(_("Match erronous chunks"), 3)
      when 6 then @prefs.maxTries = @int.get(_("Maximum trials"), 5)
      when 7 then switchBool('eject')
      when 8 then switchBool('noLog')
    else noValidChoiceMessage(choice)
    end
    loopSubMenuRipping() unless choice == 99
  end

  # show the toc (disc table of contents) submenu
  def showSubMenuToc
    @out.puts ''
    @out.puts _("*** TOC ANALYSIS PREFERENCES ***")
    @out.puts ''
    @out.puts ' 1) ' + _("Create a cuesheet %s") % [showBool(@prefs.createCue)]
    @out.puts ' 2) ' + _("Rip to single file %s") % [showBool(@prefs.image)]
    @out.puts ' 3) ' + _("Rip hidden audio sectors %s") % [showBool(@prefs.ripHiddenAudio)]
    @out.puts ' 4) ' + _("Minimum seconds hidden track") + ": %s" % [@prefs.minLengthHiddenTrack]
    @out.puts ' 5) ' + _("Append or prepend audio") + ": %s" % [@prefs.preGaps]
    @out.puts ' 6) ' + _("Way to handle pre-emphasis") + ": %s" % [@prefs.preEmphasis]
    @out.puts '99) ' + _("Back to settings main menu")
    @out.puts ""
    @int.get("Please type the number of the setting you wish to change", 99)
  end

  # loop through the toc submenu
  def loopSubMenuToc
    case choice = showSubMenuToc()
      when 99 then loopMainMenu()
      when 1 then switchBool('createCue')
      when 2 then switchBool('image')
      when 3 then switchBool('ripHiddenAudio')
      when 4 then @prefs.minLengthHiddenTrack = \
        @int.get(_("Minimum seconds hidden track"), 2)
      when 5 then setPregaps()
      when 6 then setPreEmphasis()
    else noValidChoiceMessage(choice)
    end
    loopSubMenuToc() unless choice == 99
  end

  def setPregaps
    choices = [['prepend', _('Prepend pregaps to next track')],
      ['append', _('Append pregaps to previous track')]]
    @prefs.preGaps = multipleChoice(choices)
  end

  def setPreEmphasis
    choices = [['cue', _('Write pre-emphasis tag to the cuesheet')],
      ['sox', 'Correct the audio with "sox"']]
    @prefs.preEmphasis = multipleChoice(choices)
  end

  # show the codec submenu
  def showSubMenuCodecs
    @out.puts ''
    @out.puts _("*** CODEC PREFERENCES ***")
    @out.puts ''
    @out.puts ' 1) ' + _("Flac %s") % [showBool(@prefs.flac)]
    @out.puts ' 2) ' + _("Flac options passed") + ": %s" % [@prefs.settingsFlac]
    @out.puts ' 3) ' + _("Vorbis %s") % [showBool(@prefs.vorbis)]
    @out.puts ' 4) ' + _("Oggenc options passed") + ": %s" % [@prefs.settingsVorbis]
    @out.puts ' 5) ' + _("Mp3 %s") % [showBool(@prefs.mp3)]
    @out.puts ' 6) ' + _("Lame options passed") + ": %s" % [@prefs.settingsMp3]
    @out.puts ' 7) ' + _("Wav %s") % [showBool(@prefs.wav)]
    @out.puts ' 8) ' + _("Other codec %s") % [showBool(@prefs.other)]
    @out.puts ' 9) ' + _("Commandline passed") + ": %s" % [@prefs.settingsOther]
    @out.puts '10) ' + _("Playlist support %s") %[showBool(@prefs.playlist)]
    @out.puts '11) ' + _("Maximum extra encoding threads") + ": %s" % [@prefs.maxThreads]
    @out.puts '12) ' + _("Replace spaces with underscores %s") % [showBool(@prefs.noSpaces)]
    @out.puts '13) ' + _("Downsize all capital letters in filenames %s") %[showBool(@prefs.noCapitals)]
    @out.puts '14) ' + _("Normalize program") + ": %s" % [@prefs.normalizer]
    @out.puts '15) ' + _("Normalize modus") + ": %s" % [@prefs.gain]
    @out.puts '99) ' + _("Back to settings main menu")
    @out.puts ""
    @int.get("Please type the number of the setting you wish to change", 99)
  end

  # loop through the codec submenu
  def loopSubMenuCodecs
    case choice = showSubMenuCodecs()
      when 99 then loopMainMenu()
      when 1 then switchBool('flac')
      when 2 then @prefs.settingsFlac = \
        @string.get(_("Flac options passed"), '--best -V')
      when 3 then switchBool('vorbis')
      when 4 then @prefs.settingsVorbis = \
        @string.get(_("Oggenc options passed"), '-q 4')
      when 5 then switchBool('mp3')
      when 6 then @prefs.settingsMp3 = \
        @string.get(_("Lame options passed"), '-V 3 --id3v2-only')
      when 7 then switchBool('wav')
      when 8 then switchBool('other')
      when 9 then setOtherCodec()
      when 10 then switchBool('playlist')
      when 11 then @prefs.maxThreads = \
        @int.get(_("Maximum extra encoding threads"), 2)
      when 12 then switchBool('noSpaces')
      when 13 then switchBool('noCapitals')
      when 14 then setNormalizer()
      when 15 then setNormalizeModus()
    else noValidChoiceMessage(choice)
    end
    loopSubMenuCodecs() unless choice == 99
  end

  def setOtherCodec
    @out.puts(_("%a = artist, %b = album, %g = genre, %y = year"))
    @out.puts(_("%t = trackname, %n = tracknumber, %i = inputfile"))
    @out.puts(_("%o = outputfile (don't forget the extension)"))
    @prefs.settingsOther = @string.get(_("Commandline passed"),
      'lame %i %o.mp3')
  end

  def setNormalizer
    choices = [['none', _("Don't normalize the audio")],
      ['replaygain', _('Use replaygain')],
      ['normalize', _('Use normalize')]]
    @prefs.normalizer = multipleChoice(choices)
  end

  def setNormalizeModus
    choices = [['album', _('Use album based gain')],
      ['track', _('Use track based gain')]]
    @prefs.gain = multipleChoice(choices)
  end

  # show the freedb menu
  def showSubMenuMetadata
    @out.puts ''
    @out.puts _("*** METADATA PREFERENCES ***")
    @out.puts ''
    @out.puts ' 1) ' + _("Metadata provider") + ": %s" % [@prefs.metadataProvider]
    @out.puts ' 2) ' + _("Freedb use first hit %s") % [showBool(@prefs.firstHit)]
    @out.puts ' 3) ' + _("Freedb server") + ": %s" % [@prefs.site]
    @out.puts ' 4) ' + _("Freedb username") + ": %s" % [@prefs.username]
    @out.puts ' 5) ' + _("Freedb hostname") + ": %s" % [@prefs.hostname]
    @out.puts ' 6) ' + _("Musicbrainz preferred countries (1st, 2nd,...)") + ": %s" % [@prefs.preferMusicBrainzCountries]
    @out.puts ' 7) ' + _("Musicbrainz preferred date") + ": %s" % [@prefs.preferMusicBrainzDate]
    @out.puts ' 8) ' + _("Musicbrainz use first known year (including LPs) %s") % [showBool(@prefs.useEarliestDate)]
    @out.puts '99) ' + _("Back to settings main menu")
    @out.puts ""
    @int.get("Please type the number of the setting you wish to change", 99)
  end

  # loop through the freedb menu
  def loopSubMenuMetadata
    case choice = showSubMenuMetadata()
      when 99 then loopMainMenu()
      when 1 then setMetadataProvider()
      when 2 then switchBool('firstHit')
      when 3 then @prefs.site = @string.get(_("Freedb server"),
        'http://freedb.freedb.org/~cddb/cddb.cgi')
      when 4 then @prefs.username = @string.get(_("Freedb username"),
        'anonymous')
      when 5 then @prefs.hostname = @string.get(_("Freedb hostname"),
        'my_secret.com')
      when 6 then @prefs.preferMusicBrainzCountries = @string.get(_("Prefer releases from countries (better,worse,...)"),
        'US,UK,XW,XE,JP')
      when 7 then setPreferMusicBrainzDate()
      when 8 then switchBool('useEarliestDate')
    else noValidChoiceMessage(choice)
    end
    loopSubMenuMetadata() unless choice == 99
  end
  
  def setMetadataProvider
    choices = [['none', _("Don't fetch metadata from the internet")],
      ['freedb', _('Use the freedb protocol as primary resource')],
      ['musicbrainz', _('Use the musicbrainz protocol as primary resource')]]
    @prefs.metadataProvider = multipleChoice(choices)
  end

  def setPreferMusicBrainzDate
    choices = [['earlier', _('Prefer releases with earlier dates')],
      ['later', _('Prefer releases with later dates')],
      ['no', _('Ignore dates when selecting releases')]]
    @prefs.preferMusicBrainzDate = multipleChoice(choices)
  end

  # show the other menu
  def showSubMenuOther
    @out.puts ''
    @out.puts _("*** OTHER PREFERENCES ***")
    @out.puts ''
    @out.puts ' 1) ' + _("Base directory") + ": %s" % [@prefs.basedir]
    @out.puts ' 2) ' + _("Standard filescheme") + ": %s" % [@prefs.namingNormal]
    @out.puts ' 3) ' + _("Various artist filescheme") + ": %s" % [@prefs.namingVarious]
    @out.puts ' 4) ' + _("Single file rip filescheme") + ": %s" % [@prefs.namingImage]
    @out.puts ' 5) ' + _("Log file viewer") + ": %s" % [@prefs.editor]
    @out.puts ' 6) ' + _("File manager") + ": %s" % [@prefs.filemanager]
    @out.puts ' 7) ' + _("Verbose mode %s") % [showBool(@prefs.verbose)]
    @out.puts ' 8) ' + _("Debug mode %s") % [showBool(@prefs.debug)]
    @out.puts '99) ' + _("Back to settings main menu")
    @out.puts ""
    @int.get("Please type the number of the setting you wish to change", 99)
  end

  # loop through the other menu
  def loopSubMenuOther
    case choice = showSubMenuOther()
      when 99 then loopMainMenu()
      when 1 then @prefs.basedir = @string.get(_("Base directory"),
        @prefs.basedir)
      when 2 then setDir('normal', @prefs.namingNormal)
      when 3 then setDir('various', @prefs.namingVarious)
      when 4 then setDir('image', @prefs.namingImage)
      when 5 then @prefs.editor = @string.get(_('Log file viewer'),
        @prefs.editor)
      when 6 then @prefs.filemanager = @string.get(_('File manager'),
        @prefs.filemanager)
      when 7 then switchBool('verbose')
      when 8 then switchBool('debug')
    else noValidChoiceMessage(choice)
    end
    loopSubMenuOther() unless choice == 99
  end

  # set the naming schemes
  def setDir(sort, filescheme)
    @out.puts _("\nCurrent naming scheme: %s") % [filescheme]
    showExampleForFilescheme(sort, filescheme)

    @out.puts _("\n%a = Artist\n%b = Album\n%g = Genre\n%y = Year\n%f = Codec\
      \n%n = Tracknumber\n%t = Trackname\n%va = Various Artist\n\n")

    answer = @string.get(_("New naming scheme (q to quit)"),
      "%f/%a (%y) %b/%n - %t")
    updateFilescheme(sort, answer) if answer != 'q'
  end

  def showExampleForFilescheme(sort, filescheme)
    if sort == 'normal'
      @out.puts Preferences.showFilenameNormal(@prefs.basedir, filescheme)
    else
      @out.puts Preferences.showFilenameVarious(@prefs.basedir, filescheme)
    end
  end

  def updateFilescheme(sort, answer)
    showExampleForFilescheme(sort, answer)
    case sort
      when 'normal' then @prefs.namingNormal = answer
      when 'various' then @prefs.namingVarious = answer
      when 'image' then @prefs.namingImage = answer
    end
  end
end
