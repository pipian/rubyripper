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

	# return the settings hash
	#def settings ; return @settings ; end

	# return true if user has chosen for defaults
	# def defaults ; return @options['defaults'] ; end

	# edit the current settings
	# def edit ; editSettings() ; end

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
			editSettings()
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
		@prefs.get(preference) ? '*' : ' '
	end

	# simple overview of current settings, with numbers so a user can choose what to change
	def showSettings
		puts _("*** RUBYRIPPER SETTINGS ***")
		puts ""
		puts _("** ENCODING **")
 		puts _("1)  flac [%s], settings: %s") % [showBool('flac'),
@prefs.get('settingsFlac')]
 		puts _("2)  vorbis [%s], settings: %s") % [showBool('vorbis'),
@prefs.get('settingsVorbis')]
 		puts _("3)  mp3 [%s], settings: %s") % [showBool('mp3'),
@prefs.get('settingsMp3')]
 		puts _("4)  wav [%s]") % [showBool('wav')]
 		puts _("5)  other [%s], settings: %s") % [showBool('other'), 
@prefs.get('settingsOther')]
 		puts _("6)  playlist support [%s]") % [showBool('playlist')]
 		puts _("7)  maximum extra encoding threads [%s]")  % [@prefs.get('maxThreads')]
 		puts ""
 		puts _("** RIPPING **")
 		puts _("8)  cdrom : %s with offset %s") % [@prefs.get('cdrom'),
@prefs.get('offset')]
		puts _("   **Find your offset at http://www.accuraterip.com/driveoff\
sets.htm.\n   **Your drive model is shown in the logfile.")
 		puts _("9)  passing extra cdparanoia parameters : %s") % \
[@prefs.get('rippersettings') != '' ? @prefs.get('rippersettings') : 'none']
		puts _("10) match all chunks : %s") % [@prefs.get('reqMatchesAll')]
		puts _("11) match erroneous chunks : %s") % [@prefs.get('reqMatchesErrors')]
		puts _("12) maximum trials : %s") % [@prefs.get('maxTries') == 0 ? "no\
 maximum" : @prefs.get('maxTries')]
		puts _("13) eject disc after ripping [%s]") % [showBool('eject')]
		puts ""
		puts _("** NAMING SCHEME **")
		puts _("14) base directory : %s") % [@prefs.get('basedir')]
		puts _("15) standard scheme: %s") % [@prefs.get('namingNormal')]
		puts _("16) various artist scheme: %s") % [@prefs.get('namingVarious')]
 		puts ""
 		puts _("** FREEDB  **")
		puts _("17) fetch cd info with freedb [%s]") % [showBool('freedb')]
		puts _("18) always use first hit [%s]") % [showBool('firstHit')]
		puts _("19) site = %s") % [@prefs.get('site')]
		puts _("20) username = %s") % [@prefs.get('username')]
		puts _("21) hostname = %s") % [@prefs.get('hostname')]
 		puts ""
		puts _("88) config file = %s") % [@options['file']]
 		puts _("99) Don't change any setting")
 		puts ""
	end

	# helper function to set boolean preference
	def switchBool(preference, translation)
		if @prefs.get(preference) == true
			@prefs.set(preference, value=false)
			puts _("%s disabled") % [translation]
		else
			@prefs.set(preference, value=true)
			puts _("%s enabled") % [translation]
		end
	end

	# depending on the input of the user as asked in showSettings(), change the setting
	def editSettings
		showSettings()
		while (number = @int.get(_("Please type the number of the setting you \
wish to change"), 99)) != 99
			if number == 1 ; setCodec('flac', 'settingsFlac', '--best -V')
			elsif number == 2 ; setCodec('vorbis', 'settingsVorbis', '-q 4')
			elsif number == 3 ; setCodec('mp3', 'settingsMp3', '-V 3 --id3v2-only')
			elsif number == 4 ; switchBool('wav', _('wav'))
			elsif number == 5 ; setCodec('other', 'settingsOther', '')
			elsif number == 6 ; switchBool('playlist', _('playlist'))
			elsif number == 7 ; @prefs.set('maxThreads',
@int.get(_("How many encoding threads would you like?"), 1))
			elsif number == 8 ; setCdrom()
			elsif number == 9 ; @prefs.set('rippersettings',
@string.get(_("Which options to pass to cdparanoia?"), ""))
			elsif number == 10 ; @prefs.set('reqMatchesAll',
@int.get(_("How many times must all chunks be matched?"), 2))
			elsif number == 11 ; @prefs.set('reqMatchesErrors',
@int.get(_("How many times must erroneous chunks be matched?"), 3))
			elsif number == 12 ; @prefs.set('maxTries', 
@int.get(_("What should be the maximum number of tries?"), 5))
			elsif number == 13 ; switchBool('eject', _('eject'))
			elsif number == 14 ; @prefs.set('basedir', @string.get(_("Please \
enter your directory for your encodings"), ""))
			elsif number == 15 ; setDir('normal')
			elsif number == 16 ; setDir('various')
			elsif number == 17 ; switchBool('freedb', _('freedb'))
			elsif number == 18 ; switchBool('firstHit', _('first hit'))
			elsif number == 19 ; @prefs.set('site',
@string.get(_("Freedb mirror"), "http://freedb.freedb.org/~cddb/cddb.cgi"))
			elsif number == 20 ; @prefs.set('username',
@string.get(_("Username"), "anonymous"))
			elsif number == 21 ; @prefs.set('hostname',
@string.get(_("Hostname"), "my_secret.com"))
			elsif number == 88 ; @options['file'] = @string.get(_("Config file"), @options['file'])
			else puts _("Number %s is not an option!\nPlease try again.") % [number]
			end
			puts ""
			showSettings()
		end
		# save the new settings to the configfile
		@prefs.save()
	end
	
	# update if codec is used and with what setting
	def setCodec(codec, preference, default)
		@prefs.set(codec, @bool.get("Do you want to enable #{codec} encoding?", _("y")))
		if @prefs.get(codec)
			if @bool.get(_("Do you want to change the encoding parameters for %s?)" % [codec]), _("n"))
				if codec == 'other'
					puts _("%a = artist, %b = album, %g = genre, %y = year, \
%t = trackname, %n = tracknumber, %i = inputfile, %o = outputfile (don't \
forget extension)")
				end
				@prefs.set(preference,
@string.get(_("Encoding paramaters for \%s") % [codec], default))
			end
		end
	end
	
	# set cdrom drive and it's offset
	def setCdrom
		@prefs.set('cdrom', @string.get(_("Cdrom device"), @prefs.get('cdrom')))
		@prefs.set('offset', @int.get(_("Offset for drive"), 0))
	end

	# set the naming schemes
	def setDir(variable)
		if variable == 'normal'
			puts _("\nCurrent naming scheme: %s") % [@prefs.get('namingNormal')]
			puts getExampleFilenameNormal(@prefs.get('basedir'), @prefs.get('namingNormal'))
		else 
			puts _("\nCurrent naming scheme: %s") % [@prefs.get('namingVarious')]
			puts getExampleFilenameVarious(@prefs.get('basedir'), @prefs.get('namingVarious'))
		end

		puts _("\n%a = Artist\n%b = Album\n%g = Genre\n%y = Year\n%f = Codec\n%n = Tracknumber\n%t = Trackname\n%va = Various Artist\n")
		answer = @string.get(_("New %s naming scheme (q to quit)") % [variable],
"%f/%a (%y) %b/%n - %t") 
		
		if answer != ('q')
			if variable == 'normal'
				puts _("An example filename is now:\n\n\t%s") % [getExampleFilenameNormal(@prefs.get('basedir'), answer)]
				@prefs.set('namingNormal', answer)
			else 
				puts _("An example filename is now:\n\n\t%s") % [getExampleFilenameVarious(@prefs.get('basedir'), answer)]
				@prefs.set('namingVarious', answer)
			end
		end
	end
end
