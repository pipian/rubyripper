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

require 'optparse'
require 'rubyripper/settings.rb'

# CliSettings class is responsible for showing and editing the settings
# It also interpretes the parameters when loaded
class CliSettings
	# Read the commandline options and read settings
	# * deps = instance of Dependency class
	def initialize(deps)
		@deps = deps
		parseOptions()
		readSettings()
	end

	# return the settings hash
	def settings ; return @settings ; end

	# return true if user has chosen for defaults
	def isDefault ; return @options['defaults'] ; end

	# edit the current settings
	def edit ; editSettings() ; end

private

	# Make sure the commandline options are interpreted
	def parseOptions
		@options = {'file' => false, 'version' => false, 'verbose' => false,
'configure' => false, 'defaults' => false, 'help' => false}
		setParseOptions()
		getParseOptions()
	end

	# Read the settings of the config file or the defaults
	def readSettings()
		@config = Settings.new(@deps, @options['file'])
		@settings = @config.getSettings
		
		# in case the configfile is missing
		if @options['file'] != false && !@config.isConfigFound
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

	# simple overview of current settings, with numbers so a user can choose what to change
	def showSettings
		puts _("*** RUBYRIPPER SETTINGS ***")
		puts ""
		puts _("** ENCODING **")
 		puts _("1)  flac [%s], settings: %s") % [@settings['flac'] ? '*' : ' ', @settings['flacsettings']]
 		puts _("2)  vorbis [%s], settings: %s") % [@settings['vorbis'] ? '*' : ' ', @settings['vorbissettings']]
 		puts _("3)  mp3 [%s], settings: %s") % [@settings['mp3'] ? '*' : ' ', @settings['mp3settings']]
 		puts _("4)  wav [%s]") % [@settings['wav'] ? '*' : ' ']
 		puts _("5)  other [%s], settings: %s") % [@settings['othersettings'], @settings['other'] ? '*' : ' '] 
 		puts _("6)  playlist support [%s]") % [@settings['playlist'] ? '*' : ' ']
 		puts _("7)  encode while ripping [%s]")  % [@settings['maxThreads']]
 		puts ""
 		puts _("** RIPPING **")
 		puts _("8)  cdrom : %s with offset %s") % [@settings['cdrom'], @settings['offset']]
		puts _("   **Find your offset at http://www.accuraterip.com/driveoffsets.htm.\n   **Your drive model is shown in the logfile.")
 		puts _("9)  passing extra cdparanoia parameters : %s") % [@settings['rippersettings'] != '' ? @settings['rippersettings'] : 'none']
		puts _("10) match all chunks : %s") % [@settings['req_matches_all']]
		puts _("11) match erroneous chunks : %s") % [@settings['req_matches_errors']]
		puts _("12) maximum trials : %s") % [@settings['max_tries'] == 0 ? "no maximum" : @settings['max_tries']]
		puts _("13) eject disc after ripping [%s]") % [@settings['eject'] ? '*' : ' ']
		puts ""
		puts _("** NAMING SCHEME **")
		puts _("14) base directory : %s") % [@settings['basedir']]
		puts _("15) standard scheme: %s") % [@settings['naming_normal']]
		puts _("16) various artist scheme: %s") % [@settings['naming_various']]
 		puts ""
 		puts _("** FREEDB  **")
		puts _("17) fetch cd info with freedb [%s]") % [@settings['freedb'] ? '*' : ' ']
		puts _("18) always use first hit [%s]") % [@settings['first_hit'] ? '*' : ' ']
		puts _("19) site = %s") % [@settings['site']]
		puts _("20) username = %s") % [@settings['username']]
		puts _("21) hostname = %s") % [@settings['hostname']]
 		puts ""
		puts _("88) config file = %s") % [@options['file']]
 		puts _("99) Don't change any setting")
 		puts ""
	end

	# depending on the input of the user as asked in showSettings(), change the setting
	def editSettings
		showSettings()
		while (number = getAnswer(_("Please type the number of the setting you wish to change : "), "number", 99)) != 99
			if number == 1 ; setCodec('flac')
			elsif number == 2 ; setCodec('vorbis')
			elsif number == 3 ; setCodec('mp3')
			elsif number == 4 ; if @settings['wav'] ; puts _("wav disabled") ; @settings['wav'] = false else puts _("wav enabled") ; @settings['wav'] = true end
			elsif number == 5 ; setCodec('other')
			elsif number == 6 ; if @settings['playlist'] ; puts _("playlist disabled") ; @settings['playlist'] = false else puts _("playlist enabled") ; @settings['playlist'] = true end
			elsif number == 7 ; @settings['maxThreads'] = getAnswer(_("How many encoding threads would you like? : "), "number", 1)
			elsif number == 8 ; setCdrom()
			elsif number == 9 ; @settings['rippersettings'] = getAnswer(_("Which options to pass to cdparanoia? : "), "open", "")
			elsif number == 10 ; @settings['req_matches_all'] = getAnswer(_("How many times must all chunks be matched? : "), "number", 2)
			elsif number == 11 ; @settings['req_matches_errors'] = getAnswer(_("How many times must erroneous chunks be matched? : "), "number", 3)
			elsif number == 12 ; @settings['max_tries'] = getAnswer(_("What should be the maximum number of tries? : "), "number", 5)
			elsif number == 13 ; if @settings['eject'] ; puts _("eject disabled") ; @settings['eject'] = false else puts _("eject enabled") ; @settings['eject'] = true end
			elsif number == 14 ; @settings['basedir'] = getAnswer(_("Please enter your directory for your encodings: "), "open", "")
			elsif number == 15 ; setDir('normal')
			elsif number == 16 ; setDir('various')
			elsif number == 17 ; if @settings['freedb'] ; puts _("freedb disabled") ; @settings['freedb'] = false else puts _("freedb enabled") ; @settings['freedb'] = true end
			elsif number == 18 ; if @settings['first_hit'] ; puts _("first hit disabled") ; @settings['first_hit'] = false else puts _("first hit enabled") ; @settings['first_hit'] = true end
			elsif number == 19 ; @settings['site'] = getAnswer(_("Freedb mirror: "), "open", "freedb.org")
			elsif number == 20 ; @settings['username'] = getAnswer(_("Username : "), "open", "anonymous")
			elsif number == 21 ; @settings['hostname'] = getAnswer(_("Hostname : "), "open", "my_secret.com")
			elsif number == 88 ; @options['file'] = getAnswer(_("Config file : "), "open", @options['file'])
			else puts _("Number %s is not an option!\nPlease try again.") % [number]
			end
			puts ""
			showSettings()
		end
		@config.save(@settings)
	end
	
	# update if codec is used and with what setting
	def setCodec(codec)
		@settings[codec] = getAnswer("Do you want to enable #{codec} encoding? (y/n) : ", "yes", _("y"))
		if @settings[codec]
			if getAnswer(_("Do you want to change the encoding parameters for %s? (y/n) : ") % [codec], "yes", _("n"))
				if codec == 'other' ; puts _("%a = artist, %b = album, %g = genre, %y = year, %t = trackname, %n = tracknumber, %i = inputfile, %o = outputfile (don't forget extension)") end
				@settings[codec + 'settings'] = getAnswer(_("Encoding paramaters for %s : ") % [codec], "open", "")
			end
		end
	end
	
	# set cdrom drive and it's offset
	def setCdrom
		@settings['cdrom'] = getAnswer(_("Cdrom device : "), "open", @settings['cdrom'])
		@settings['offset'] = getAnswer(_("Offset for drive : "), "number", 0)
	end

	# set the naming schemes
	def setDir(variable)
		if variable == 'normal'
			puts _("\nCurrent naming scheme: %s") % [@settings['naming_normal']]
			puts getExampleFilenameNormal(@settings['basedir'], @settings['naming_normal'])
		else 
			puts _("\nCurrent naming scheme: %s") % [@settings['naming_various']]
			puts getExampleFilenameVarious(@settings['basedir'], @settings['naming_various'])
		end

		puts _("\n%a = Artist\n%b = Album\n%g = Genre\n%y = Year\n%f = Codec\n%n = Tracknumber\n%t = Trackname\n%va = Various Artist\n")
		answer = getAnswer(_("New %s naming scheme (q to quit) : ") % [variable], "open", "%f/%a (%y) %b/%n - %t") 
		if answer !=_('q')
			if variable == 'normal'
				puts _("An example filename is now:\n\n\t%s") % [getExampleFilenameNormal(@settings['basedir'], answer)]
				@settings['naming_normal'] = answer
			else 
				puts _("An example filename is now:\n\n\t%s") % [getExampleFilenameVarious(@settings['basedir'], answer)]
				@settings['naming_various'] = answer
			end
		end
	end
end
