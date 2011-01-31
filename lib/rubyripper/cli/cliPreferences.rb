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

# CliPreferences is responsible for showing and editing the preferences
# It also interpretes the parameters when loaded
class CliPreferences

	# * preferences = instance of Preferences class
	# * cliGetInt = instance of CliGetInt class
	# * cliGetBool = instance of CliGetBool class
	# * cliGetString = instance of CliGetString class
	def initialize(preferences, cliGetInt, cliGetBool, cliGetString)
		@prefs = preferences
		@int = cliGetInt
		@bool = cliGetBool
		@string = cliGetString
	end

	# Read the preferences + startup options and decide if action is needed
	def readPrefs
		parseOptions()
		readPreferences()
	end

	# return true if user has chosen for defaults
	def defaults ; return @options['defaults'] ; end

	# edit the current settings
	def edit ; showMainMenu() ; end

private

	# Make sure the commandline options are interpreted
	def parseOptions
		@options = {'file' => false, 'version' => false, 'verbose' => false,
'configure' => false, 'defaults' => false, 'help' => false}
		setParseOptions()
		getParseOptions()
	end

	# Read the settings of the config file or the defaults
	def readPreferences()
		# if file is still false it will be ignored by @prefs
		@prefs.loadConfig(configFile = @options['file'])
		
		# in case the configfile is missing
		if @options['file'] != false && !@prefs.isConfigFound
			puts "WARNING: the provided configfile is not found."
			puts "The default settings are used instead."
		end
		
		if @options['configure']
			loopMainMenu()
		end
	end
	
	# First define the different options
	def setParseOptions
		@opts = OptionParser.new(banner = nil, width = 20, indent = ' ' * 2) do |opts|
			opts.on("-V", "--version", _("Show current version of rubyripper.")) do
				puts "Rubyripper version #{$rr_version}."
				@options['version'] = true
			end
			opts.on("-f", "--file <FILE>", _("Load configuration settings from file <FILE>.")) do |f|
				@options['file'] = f
			end
			opts.on("-v", "--verbose", _("Display verbose output.")) do |v|
				@options['verbose'] = v
			end
			opts.on("-c", "--configure", _("Change configuration settings.")) do |c|
				@options['configure'] = c
			end
			opts.on("-d", "--defaults", _("Skip questions and rip the disc.")) do |d|
				@options['defaults'] = true
			end
			opts.on_tail("-h", "--help", _("Show this usage statement.")) do |h|
				puts opts
				@options['help'] = h
			end
		end
	end

	# Then read the different options
	def getParseOptions
		begin
			@opts.parse!(ARGV)
		rescue Exception => e
			puts "The loading of the input swithes crashed.", e, @opts
			exit()
		end

		if @options['help'] || @options['version']; exit end

		puts _("Verbose output specified.") if @options['verbose']
		puts _("Configure option specified.") if @options['configure']
		puts _("Skip questions and rip the disc.") if @options['defaults']
		puts _("Use config file ") + @options['file'] if @options['file']
	end

	# helper function to show boolean preference
	def showBool(preference)
		@prefs.get(preference) ? '[*]' : '[ ]'
	end

	# helper function to set boolean preference
	def switchBool(preference)
		if @prefs.get(preference) == true
			@prefs.set(preference, value=false)
		else
			@prefs.set(preference, value=true)
		end
	end

	# helper function to ask an option from multiple choices
	# choices is an array with possibilities
	# each choice is an array in its turn with ['preference', 'text shown to user']
	def multipleChoice(choices)
		puts _("\nThere are #{choices.size} choices:\n")
		choices.each_index do |index|
			puts " #{index+1}) #{choices[index][1]}"
		end
		choice = @int.get("\nWhich one do you prefer?", 1)
		return choices[choice - 1][0]
	end

	# show a menu for the different settings
	def showMainMenu
		puts ""
		puts _("*** RUBYRIPPER SETTINGS ***")
		puts ""
		puts ' 1) ' + _('Secure ripping')
		puts ' 2) ' + _('Toc analysis')
		puts ' 3) ' + _('Codecs')
		puts ' 4) ' + _('Freedb')
		puts ' 5) ' + _('Other')
		puts '99) ' + _("Don't change any setting")
		puts ""
		@int.get("Please type the number of the setting you wish to change", 99)
	end

	# loop through the main menu
	def loopMainMenu
		choice = showMainMenu()
		if choice == 99
			# save the new settings to the configfile
			@prefs.save()
		else
			if choice == 1 ; loopSubMenuRipping()
			elsif choice == 2 ; loopSubMenuToc()
			elsif choice == 3 ; loopSubMenuCodecs()
			elsif choice == 4 ; loopSubMenuFreedb()
			elsif choice == 5 ; loopSubMenuOther()
			else
				puts _("Number #{choice} is not a valid choice, try again")
				loopMainMenu()
			end
		end
	end

	# show the ripping submenu
	def showSubMenuRipping
		puts ''		
		puts _("** SECURE RIPPING SETTINGS **")
		puts ''
 		puts ' 1) ' + _("Ripping drive") + ": %s" %[@prefs.get('cdrom')]
		puts ' 2) ' + _("Drive offset") + ": %s" % [@prefs.get('offset')]
		puts _("   **Find your offset at http://www.accuraterip.com/driveoff\
sets.htm.\n   **Your drive model is shown in the logfile.")
 		puts ' 3) ' + _("Passing extra cdparanoia parameters") + ": %s" % [@prefs.get('rippersettings')]
		puts ' 4) ' + _("Match all chunks") + ": %s" % [@prefs.get('reqMatchesAll')]
		puts ' 5) ' + _("Match erroneous chunks") + ": %s" % [@prefs.get('reqMatchesErrors')]
		puts ' 6) ' + _("Maximum trials") + ": %s" % [@prefs.get('maxTries') == 0 ? "no\
 maximum" : @prefs.get('maxTries')]
		puts ' 7) ' + _("Eject disc after ripping %s") % [showBool('eject')]
		puts ' 8) ' + _("Only keep log when errors %s") % [showBool('noLog')]
		puts '99) ' + _("Back to settings main menu")
		puts ""
		@int.get("Please type the number of the setting you wish to change", 99)
	end

	# loop through the ripping submenu
	def loopSubMenuRipping
		choice = showSubMenuRipping()
		if choice == 99
			loopMainMenu()
		else
			if choice == 1
@prefs.set('cdrom', @string.get(_("Ripping drive"), @prefs.get('cdrom')))
			elsif choice == 2
@prefs.set('offset', @int.get(_("Drive offset"), 0))
			elsif choice == 3
@prefs.set('rippersettings', @string.get(_("Passing extra cdparanoia parameters"), ""))
			elsif choice == 4
@prefs.set('reqMatchesAll', @int.get(_("Match all chunks"), 2))
			elsif choice == 5
@prefs.set('reqMatchesErrors', @int.get(_("Match erronous chunks"), 3))
			elsif choice == 6
@prefs.set('maxTries', @int.get(_("Maximum trials"), 5))
			elsif choice == 7 ; switchBool('eject')
			elsif choice == 8 ; switchBool('noLog') 
			else
				puts _("Number #{choice} is not a valid choice, try again.")
			end
			loopSubMenuRipping()
		end
	end

	# show the toc (disc table of contents) submenu
	def showSubMenuToc
		puts ''		
		puts _("** TOC ANALYSIS SETTINGS **")
		puts ''
 		puts ' 1) ' + _("Create a cuesheet %s") % [showBool('createCue')]
		puts ' 2) ' + _("Rip to single file %s") % [showBool('image')]
 		puts ' 3) ' + _("Rip hidden audio sectors %s") % [showBool('ripHiddenAudio')]
		puts ' 4) ' + _("Minimum seconds hidden track") + ": %s" % [@prefs.get('minLengthHiddenTrack')]
		puts ' 5) ' + _("Append or prepend audio") + ": %s" % [@prefs.get('preGaps')]
		puts ' 6) ' + _("Way to handle pre-emphasis") + ": %s" % [@prefs.get('preEmphasis')]
		puts '99) ' + _("Back to settings main menu")
		puts ""
		@int.get("Please type the number of the setting you wish to change", 99)
	end

	# loop through the toc submenu
	def loopSubMenuToc
		choice = showSubMenuToc()
		if choice == 99
			loopMainMenu()
		else
			if choice == 1 ; switchBool('createCue')
			elsif choice == 2 ; switchBool('image')
			elsif choice == 3 ; switchBool('ripHiddenAudio')
			elsif choice == 4
@prefs.set('minLengthHiddenTrack', @int.get(_("Minimum seconds hidden track"), 2))
			elsif choice == 5
				choices = [['prepend', _('Prepend pregaps to next track')],
					['append', _('Append pregaps to previous track')]] 
				@prefs.set('preGaps', multipleChoice(choices))
			elsif choice == 6
				choices = [['cue', _('Write pre-emphasis tag to the cuesheet')],
					['sox', 'Correct the audio with "sox"']]
				@prefs.set('preEmphasis', multipleChoice(choices))
			else
				puts _("Number #{choice} is not a valid choice, try again.")
			end
			loopSubMenuToc()
		end
	end

	# show the codec submenu
	def showSubMenuCodecs
		puts ''		
		puts _("** CODEC SETTINGS **")
		puts ''
 		puts ' 1) ' + _("Flac %s") % [showBool('flac')]
		puts ' 2) ' + _("Flac options passed") + ": %s" % [@prefs.get('settingsFlac')]
 		puts ' 3) ' + _("Vorbis %s") % [showBool('vorbis')]
		puts ' 4) ' + _("Oggenc options passed") + ": %s" % [@prefs.get('settingsVorbis')]
		puts ' 5) ' + _("Mp3 %s") % [showBool('mp3')]
		puts ' 6) ' + _("Lame options passed") + ": %s" % [@prefs.get('settingsMp3')]
		puts ' 7) ' + _("Wav %s") % [showBool('wav')]
		puts ' 8) ' + _("Other codec %s") % [showBool('other')]
		puts ' 9) ' + _("Commandline passed") + ": %s" % [@prefs.get('settingsOther')]
		puts '10) ' + _("Playlist support %s") %[showBool('playlist')]
		puts '11) ' + _("Maximum extra encoding threads") + ": %s" %[@prefs.get('maxThreads')]
		puts '12) ' + _("Replace spaces with underscores %s") % [showBool('noSpaces')]
		puts '13) ' + _("Downsize all capital letters in filenames %s") %[showBool('noCapitals')]
		puts '99) ' + _("Back to settings main menu")
		puts ""
		@int.get("Please type the number of the setting you wish to change", 99)
	end

	# loop through the codec submenu
	def loopSubMenuCodecs
		choice = showSubMenuCodecs()
		if choice == 99
			loopMainMenu()
		else
			if choice == 1 ; switchBool('flac')
			elsif choice == 2
@prefs.set('settingsFlac', @string.get(_("Flac options passed"), '--best -V'))
			elsif choice == 3 ; switchBool('vorbis')
			elsif choice == 4
@prefs.set('settingsVorbis', @string.get(_("Oggenc options passed"), '-q 4'))
			elsif choice == 5 ; switchBool('mp3')
			elsif choice == 6
@prefs.set('settingsMp3', @string.get(_("Lame options passed"), '-V 3 --id3v2-only'))
			elsif choice == 7 ; switchBool('wav')
			elsif choice == 8 ; switchBool('other')
			elsif choice == 9
				puts _("%a = artist, %b = album, %g = genre, %y = year, \
%t = trackname, %n = tracknumber, %i = inputfile, %o = outputfile (don't \
forget extension)")
@prefs.set('settingsOther', @string.get(_("Commandline passed"), 'lame %i %o.mp3'))
			elsif choice == 10 ; switchBool('playlist')
			elsif choice == 11
@prefs.set('maxThreads', @int.get(_("Maximum extra encoding threads"), 2))
			elsif choice == 12 ; switchBool('noSpaces')
			elsif choice == 13 ; switchBool('noCapitals')
			else
				puts _("Number #{choice} is not a valid choice, try again.")
			end
			loopSubMenuCodecs()
		end
	end
	
	# show the freedb menu
	def showSubMenuFreedb
		puts ''		
		puts _("** FREEDB SETTINGS **")
		puts ''
 		puts ' 1) ' + _("Fetch cd info with freedb %s") % [showBool('freedb')]
		puts ' 2) ' + _("Always use first hit %s") % [showBool('firstHit')]
		puts ' 3) ' + _("Freedb server") + ": %s" % [@prefs.get('site')]
		puts ' 4) ' + _("Freedb username") + ": %s" % [@prefs.get('username')]
		puts ' 5) ' + _("Freedb hostname") + ": %s" % [@prefs.get('hostname')]
		puts '99) ' + _("Back to settings main menu")
		puts ""
		@int.get("Please type the number of the setting you wish to change", 99)
	end

	# loop through the freedb menu
	def loopSubMenuFreedb
		choice = showSubMenuFreedb()
		if choice == 99
			loopMainMenu()
		else
			if choice == 1 ; switchBool('freedb')
			elsif choice == 2 ; switchBool('firstHit')
			elsif choice == 3
@prefs.set('site', @string.get(_("Freedb server"), 'http://freedb.freedb.org/~cddb/cddb.cgi'))
			elsif choice == 4
@prefs.set('username', @string.get(_("Freedb username"), 'anonymous'))
			elsif choice == 5
@prefs.set('hostname', @string.get(_("Freedb hostname"), 'my_secret.com'))
			else
				puts _("Number #{choice} is not a valid choice, try again.")
			end
			loopSubMenuFreedb()
		end
	end

	# show the other menu
	def showSubMenuOther
		puts ''
		puts _("** OTHER SETTINGS **")
		puts ''
		puts ' 1) ' + _("Base directory") + ": %s" % [@prefs.get('basedir')]
		puts ' 2) ' + _("Standard filescheme") + ": %s" % [@prefs.get('namingNormal')]
		puts ' 3) ' + _("Various artist filescheme") + ": %s" % [@prefs.get('namingVarious')]
		puts ' 4) ' + _("Single file rip filescheme") + ": %s" % [@prefs.get('namingImage')]
		puts ' 5) ' + _("Log file viewer") + ": %s" % [@prefs.get('editor')]
		puts ' 6) ' + _("File manager") + ": %s" % [@prefs.get('filemanager')]
		puts ' 7) ' + _("Verbose mode %s") % [showBool('verbose')]
		puts ' 8) ' + _("Debug mode %s") % [showBool('debug')]
		puts '99) ' + _("Back to settings main menu")
		puts ""
		@int.get("Please type the number of the setting you wish to change", 99)
	end

	def loopSubMenuOther
		choice = showSubMenuOther()
		if choice == 99
			loopMainMenu()
		else
			if choice == 1
@prefs.set('basedir', @string.get(_("Base directory"), @prefs.get('basedir')))
			elsif choice == 2 ; setDir('namingNormal')
			elsif choice == 3 ; setDir('namingVarious')
			elsif choice == 4 ; setDir('namingImage')
			elsif choice == 5
@prefs.set('editor', @string.get(_('Log file viewer'), @prefs.get('editor')))
			elsif choice == 6
@prefs.set('filemanager', @string.get(_('File manager'), @prefs.get('filemanager')))
			elsif choice == 7 ; switchBool('verbose')
			elsif choice == 8 ; switchBool('debug')
			else
				puts _("Number #{choice} is not a valid choice, try again.")
			end
			loopSubMenuOther()
		end
	end

	# set the naming schemes
	def setDir(filescheme)
		puts _("\nCurrent naming scheme: %s") % [@prefs.get(filescheme)]

		if filescheme == 'namingNormal'
			puts getExampleFilenameNormal(@prefs.get('basedir'), @prefs.get(filescheme))
		else 
			puts getExampleFilenameVarious(@prefs.get('basedir'), @prefs.get(filescheme))
		end

		puts _("\n%a = Artist\n%b = Album\n%g = Genre\n%y = Year\n%f = Codec\n%n = Tracknumber\n%t = Trackname\n%va = Various Artist\n\n")
		answer = @string.get(_("New %s naming scheme (q to quit)") % [filescheme],
"%f/%a (%y) %b/%n - %t") 
		
		if answer != 'q'
			if filescheme == 'namingNormal'
				puts _("An example filename is now:\n\n\t%s") % [getExampleFilenameNormal(@prefs.get('basedir'), answer)]
				@prefs.set(filescheme, answer)
			else 
				puts _("An example filename is now:\n\n\t%s") % [getExampleFilenameVarious(@prefs.get('basedir'), answer)]
				@prefs.set(filescheme, answer)
			end
		end
	end
end
