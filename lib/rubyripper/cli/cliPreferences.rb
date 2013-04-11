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

# helper for interpreting commandline options
require 'optparse'
require 'rubyripper/preferences/main'
require 'rubyripper/cli/cliGetAnswer'

# CliPreferences is responsible for showing and editing the preferences
# It also interpretes the parameters when loaded
class CliPreferences
  include GetText
  GetText.bindtextdomain("rubyripper")

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
    # Force CD-ROM device when given a --testdisc (for Cucumber tests)
    @prefs.cdrom = '/dev/cdrom' if @prefs.testdisc

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
    @out.puts _("\nThere are %s choices:\n") % [choices.size]
    choices.each_index do |index|
      @out.puts " #{index+1}) #{choices[index][1]}"
    end

    choice = @int.get(_("\nWhich one do you prefer?"), 1)

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
    @out.puts "** " + _("RUBYRIPPER PREFERENCES") + " **"
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
    @out.puts _("Number %s is not a valid choice, try again") % [choice]
  end

  # show the ripping submenu
  def showSubMenuRipping
    @out.puts ''
    @out.puts "*** " + _("SECURE RIPPING PREFERENCES") + " ***"
    @out.puts ''
    @out.puts ' 1) ' + _("Ripping drive") + ": %s" %[@prefs.cdrom]
    @out.puts ' 2) ' + _("Drive offset") + ": %s" % [@prefs.offset]
    @out.puts "    **" + _("Find your offset at http://www.accuraterip.com/driveoffsets.htm.")
    @out.puts "    **" + _("Your drive model is shown in the logfile.")
    @out.puts ' 3) ' + _("Pad missing lead-in/lead-out samples with zeroes %s") % [showBool(@prefs.padMissingSamples)]
    @out.puts ' 4) ' + _("Passing extra cdparanoia parameters") + ": %s" % [@prefs.rippersettings]
    @out.puts ' 5) ' + _("Match all chunks") + ": %s" % [@prefs.reqMatchesAll]
    @out.puts ' 6) ' + _("Match erroneous chunks") + ": %s" % [@prefs.reqMatchesErrors]
    @out.puts ' 7) ' + _("Maximum trials") + ": %s" % [@prefs.maxTries == 0 ? "no\
 maximum" : @prefs.maxTries]
    @out.puts ' 8) ' + _("Eject disc after ripping %s") % [showBool(@prefs.eject)]
    @out.puts ' 9) ' + _("Only keep log when errors %s") % [showBool(@prefs.noLog)]
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
      when 3 then switchBool('padMissingSamples')
      when 4 then @prefs.rippersettings = \
        @string.get(_("Passing extra cdparanoia parameters"), "")
      when 5 then @prefs.reqMatchesAll = @int.get(_("Match all chunks"), 2)
      when 6 then @prefs.reqMatchesErrors = @int.get(_("Match erronous chunks"), 3)
      when 7 then @prefs.maxTries = @int.get(_("Maximum trials"), 5)
      when 8 then switchBool('eject')
      when 9 then switchBool('noLog')
    else noValidChoiceMessage(choice)
    end
    loopSubMenuRipping() unless choice == 99
  end

  # show the toc (disc table of contents) submenu
  def showSubMenuToc
    @out.puts ''
    @out.puts "*** " + _("TOC ANALYSIS PREFERENCES") + " ***"
    @out.puts ''
    @out.puts ' 1) ' + _("Create a cuesheet %s") % [showBool(@prefs.createCue)]
    @out.puts ' 2) ' + _("Rip to single file %s") % [showBool(@prefs.image)]
    @out.puts ' 3) ' + _("Rip hidden audio sectors %s") % [showBool(@prefs.ripHiddenAudio)]
    @out.puts ' 4) ' + _("Mark as a hidden track when longer than") + ": %s " % [@prefs.minLengthHiddenTrack] + _("second(s)")
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
        @int.get(_("Mark as a hidden track when bigger than <X> seconds"), 2)
      when 5 then setPregaps()
      when 6 then setPreEmphasis()
    else noValidChoiceMessage(choice)
    end
    loopSubMenuToc() unless choice == 99
  end

  def setPregaps
    choices = [['prepend', _('Prepend pregaps to the track')],
      ['append', _('Append pregap to previous track')]]
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
    @out.puts "*** " + _("CODEC PREFERENCES") + " ***"
    @out.puts ''
    @out.puts ' 1) ' + _("FLAC %s") % [showBool(@prefs.flac)]
    @out.puts ' 2) ' + _("FLAC options passed") + ": %s" % [@prefs.settingsFlac]
    @out.puts ' 3) ' + _("Vorbis %s") % [showBool(@prefs.vorbis)]
    @out.puts ' 4) ' + _("Oggenc options passed") + ": %s" % [@prefs.settingsVorbis]
    @out.puts ' 5) ' + _("LAME mp3 %s") % [showBool(@prefs.mp3)]
    @out.puts ' 6) ' + _("LAME options passed") + ": %s" % [@prefs.settingsMp3]
    @out.puts ' 7) ' + _("Nero AAC %s") % [showBool(@prefs.nero)]
    @out.puts ' 8) ' + _("Nero options passed") + ": %s" % [@prefs.settingsNero]
    @out.puts ' 9) ' + _("Fraunhofer AAC %s") % [showBool(@prefs.fraunhofer)]
    @out.puts '10) ' + _("Fraunhofer options passed") + ": %s" % [@prefs.settingsFraunhofer]
    @out.puts '11) ' + _("WavPack %s") % [showBool(@prefs.wavpack)]
    @out.puts '12) ' + _("WavPack options passed") + ": %s" % [@prefs.settingsWavpack]
    @out.puts '13) ' + _("Opus %s") % [showBool(@prefs.opus)]
    @out.puts '14) ' + _("Opus options passed") + ": %s" % [@prefs.settingsOpus]
    @out.puts '15) ' + _("WAVE %s") % [showBool(@prefs.wav)]
    @out.puts '16) ' + _("Other codec %s") % [showBool(@prefs.other)]
    @out.puts '17) ' + _("Commandline passed") + ": %s" % [@prefs.settingsOther]
    @out.puts '18) ' + _("Playlist support %s") %[showBool(@prefs.playlist)]
    @out.puts '19) ' + _("Maximum extra encoding threads") + ": %s" % [@prefs.maxThreads]
    @out.puts '20) ' + _("Replace spaces with underscores %s") % [showBool(@prefs.noSpaces)]
    @out.puts '21) ' + _("Downsize all capital letters in file names %s") %[showBool(@prefs.noCapitals)]
    @out.puts '22) ' + _("Normalize program") + ": %s" % [@prefs.normalizer]
    @out.puts '23) ' + _("Normalize modus") + ": %s" % [@prefs.gain]
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
        @string.get(_("FLAC options passed"), @prefs.settingsFlac)
      when 3 then switchBool('vorbis')
      when 4 then @prefs.settingsVorbis = \
        @string.get(_("Oggenc options passed"), @prefs.settingsVorbis)
      when 5 then switchBool('mp3')
      when 6 then @prefs.settingsMp3 = \
        @string.get(_("Lame options passed"), @prefs.settingsMp3)
      when 7 then switchBool('nero')
      when 8 then @prefs.settingsNero = \
        @string.get(_("Nero options passed"), @prefs.settingsNero)
      when 9 then switchBool('fraunhofer')
      when 10 then @prefs.settingsFraunhofer = \
        @string.get(_("Fraunhofer options passed"), @prefs.settingsFraunhofer)
      when 11 then switchBool('wavpack')
      when 12 then @prefs.settingsWavpack = \
        @string.get(_("WavPack options passed"), @prefs.settingsWavpack)
      when 13 then switchBool('opus')
      when 14 then @prefs.settingsOpus = \
        @string.get(_("Opus options passed"), @prefs.settingsOpus)
      when 15 then switchBool('wav')
      when 16 then switchBool('other')
      when 17 then setOtherCodec()
      when 18 then switchBool('playlist')
      when 19 then @prefs.maxThreads = \
        @int.get(_("Maximum extra encoding threads"), 2)
      when 20 then switchBool('noSpaces')
      when 21 then switchBool('noCapitals')
      when 22 then setNormalizer()
      when 23 then setNormalizeModus()
    else noValidChoiceMessage(choice)
    end
    loopSubMenuCodecs() unless choice == 99
  end

  def setOtherCodec
    @out.puts("%a = " + _("Artist") + ", %b = " + _("Album") + ", %g = " + _("Genre") + ", %y = " + _("Year"))
    @out.puts("%t = " + _("Track name") + ", %n = " + _("Tracknumber") + ", %i = " + _("Input file"))
    @out.puts("%o = " + _("Output file") + _(" (don't forget the extension)"))
    @prefs.settingsOther = @string.get(_("Commandline passed"), 'lame %i %o.mp3')
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
    @out.puts "*** " + _("METADATA PREFERENCES") + " ***"
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
      when 6 then @prefs.preferMusicBrainzCountries = @string.get(_("Prefer releases from countries (better, worse, ...)"),
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
    @out.puts "*** " + _("OTHER PREFERENCES") + " ***"
    @out.puts ''
    @out.puts ' 1) ' + _("Base directory") + ": %s" % [@prefs.basedir]
    @out.puts ' 2) ' + _("Standard file scheme") + ": %s" % [@prefs.namingNormal]
    @out.puts ' 3) ' + _("Various artist file scheme") + ": %s" % [@prefs.namingVarious]
    @out.puts ' 4) ' + _("Single file rip file scheme") + ": %s" % [@prefs.namingImage]
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

    @out.puts("\n%a = " + _("Artist") + "\n%b = " + _("Album") +
        "\n%g = " + _("Genre")+ "\n%y = " + _("Year") + "\n%f = " +
        _("Codec") + "\n%n = " + _("Tracknumber") + "\n%t = " +
        _("Track name") + "\n%va = " + _("Various Artist") + "\n\n")

    answer = @string.get(_("New naming scheme (q to quit)"),
      "%f/%a (%y) %b/%n - %t")
    updateFilescheme(sort, answer) if answer != 'q'
  end

  def showExampleForFilescheme(sort, filescheme)
    print _("Example file name: ")
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
