#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007  Bouke Woudstra (rubyripperdev@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

RUBYDIR=[ENV['PWD'], File.dirname(__FILE__), "/usr/local/lib/ruby/site_ruby/1.8"]

found_rrlib = false
RUBYDIR.each do |dir|
  if File.exist?(file = File.join(dir, '/rr_lib.rb'))
	require file; found_rrlib = true ; break
  end
end
if found_rrlib == false
  puts "The main program logic file 'rr_lib.rb' can't be found!"
  exit()
end

require 'optparse'
require 'ostruct'

class Gui_CLI
	attr_reader :update
	def initialize()
		parse_options()
		@ripping_log = ""
		@ripping_progress = 0.0
		@encoding_progress = 0.0
		@settingsClass = Settings.new(@options.file)
		@settings = @settingsClass.settings
		
		if !@settingsClass.configFound || @options.configure
			edit_settings()
		else
			get_cd_info()
		end
	end

	def parse_options
		@options = OpenStruct.new
		@options.file = false
		@options.version = false
		@options.help = false
		@options.verbose = false
		@options.configure = false
		@options.defaults = false
		@options.help = false

		opts = OptionParser.new(banner = nil, width = 20, indent = ' ' * 2) do |opts|
			opts.on("-V", "--version", _("Show current version of rubyripper.")) do
				puts "Rubyripper version #{$rr_version}."
				@options.version = true
			end
			opts.on("-f", "--file <FILE>", _("Load configuration settings from file <FILE>.")) do |f|
				@options.file = f
			end
			opts.on("-v", "--verbose", _("Display verbose output.")) do |v|
				@options.verbose = v
			end
			opts.on("-c", "--configure", _("Change configuration settings.")) do |c|
				@options.configure = c
			end
			opts.on("-d", "--defaults", _("Skip questions and rip the disc.")) do |d|
				@options.defaults = true
			end
			opts.on_tail("-h", "--help", _("Show this usage statement.")) do |h|
				puts opts
				@options.help = h
			end
		end

		begin
			opts.parse!(ARGV)
			rescue Exception => e
			puts e, "", opts
			exit
		end

		if @options.help || @options.version; exit end

		puts _("Verbose output specified.") if @options.verbose
		puts _("Configure option specified.") if @options.configure
		puts _("Skip questions and rip the disc.") if @options.defaults
		puts _("Use config file ") + @options.file if @options.file
	end
	
	def show_settings # simple overview of current settings, with numbers so a user can choose what to change
		puts _("*** RUBYRIPPER SETTINGS ***")
		puts ""
		puts _("** ENCODING **")
 		puts _("1)  flac [%s] , settings: %s") % [@settings['flac'] ? '*' : ' ', @settings['flacsettings']]
 		puts _("2)  vorbis [%s] , settings: %s") % [@settings['vorbis'] ? '*' : ' ', @settings['vorbissettings']]
 		puts _("3)  mp3 [%s] , settings: %s") % [@settings['mp3'] ? '*' : ' ', @settings['mp3settings']]
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
		puts _("88) config file = %s") % [@options.file]
 		puts _("99) Don't change any setting")
 		puts ""
	end

	def edit_settings # depending on the input of the user as asked in show_settings(), change the setting
		show_settings()
		while (number = get_answer(_("Please type the number of the setting you wish to change : "), "number", 99)) != 99
			if number == 1 ; set_codec('flac')
			elsif number == 2 ; set_codec('vorbis')
			elsif number == 3 ; set_codec('mp3')
			elsif number == 4 ; if @settings['wav'] ; puts _("wav disabled") ; @settings['wav'] = false else puts _("wav enabled") ; @settings['wav'] = true end
			elsif number == 5 ; set_codec('other')
			elsif number == 6 ; if @settings['playlist'] ; puts _("playlist disabled") ; @settings['playlist'] = false else puts _("playlist enabled") ; @settings['playlist'] = true end
			elsif number == 7 ; @settings['maxThreads'] = get_answer(_("How many encoding threads would you like? : "), "number", 1)
			elsif number == 8 ; set_cdrom()
			elsif number == 9 ; @settings['rippersettings'] = get_answer(_("Which options to pass to cdparanoia? : "), "open", "")
			elsif number == 10 ; @settings['req_matches_all'] = get_answer(_("How many times must all chunks be matched? : "), "number", 2)
			elsif number == 11 ; @settings['req_matches_errors'] = get_answer(_("How many times must erroneous chunks be matched? : "), "number", 3)
			elsif number == 12 ; @settings['max_tries'] = get_answer(_("What should be the maximum number of tries? : "), "number", 5)
			elsif number == 13 ; if @settings['eject'] ; puts _("eject disabled") ; @settings['eject'] = false else puts _("eject enabled") ; @settings['eject'] = true end
			elsif number == 14 ; @settings['basedir'] = get_answer(_("Please enter your directory for your encodings: "), "open", "")
			elsif number == 15 ; setdir('normal')
			elsif number == 16 ; setdir('various')
			elsif number == 17 ; if @settings['freedb'] ; puts _("freedb disabled") ; @settings['freedb'] = false else puts _("freedb enabled") ; @settings['freedb'] = true end
			elsif number == 18 ; if @settings['first_hit'] ; puts _("first hit disabled") ; @settings['first_hit'] = false else puts _("first hit enabled") ; @settings['first_hit'] = true end
			elsif number == 19 ; @settings['site'] = get_answer(_("Freedb mirror: "), "open", "freedb.org")
			elsif number == 20 ; @settings['username'] = get_answer(_("Username : "), "open", "anonymous")
			elsif number == 21 ; @settings['hostname'] = get_answer(_("Hostname : "), "open", "my_secret.com")
			elsif number == 88 ; @options.file = get_answer(_("Config file : "), "open", @options.file)
			else puts _("Number %s is not an option!\nPlease try again.") % [number]
			end
			puts ""
			show_settings()
		end
		@settingsClass.save(@settings)
		if get_answer(_("Do you want to continue with the program now? (y/n) : "), "yes", _("y"))
			get_cd_info()
		else
			exit()
		end
	end
	
	def set_codec(codec) # little help function for edit_settings
		@settings[codec] = get_answer("Do you want to enable #{codec} encoding? (y/n) : ", "yes", _("y"))
		if @settings[codec]
			if get_answer(_("Do you want to change the encoding parameters for %s? (y/n) : ") % [codec], "yes", _("n"))
				if codec == 'other' ; puts _("%a = artist, %b = album, %g = genre, %y = year, %t = trackname, %n = tracknumber, %i = inputfile, %o = outputfile (don't forget extension)") end
				@settings[codec + 'settings'] = get_answer(_("Encoding paramaters for %s : ") % [codec], "open", "")
			end
		end
	end
	
	def set_cdrom # little help function for edit_settings
		@settings['cdrom'] = get_answer(_("Cdrom device : "), "open", @settings['cdrom'])
		@settings['offset'] = get_answer(_("Offset for drive : "), "number", 0)
	end

	def setdir(variable)
		if variable == 'normal'
			puts _("\nCurrent naming scheme: %s") % [@settings['naming_normal']]
			puts get_example_filename_normal(@settings['basedir'], @settings['naming_normal'])
		else 
			puts _("\nCurrent naming scheme: %s") % [@settings['naming_various']]
			puts get_example_filename_various(@settings['basedir'], @settings['naming_various'])
		end

		puts	_("\n%a = Artist	\n%b = Album\n%g = Genre\n%y = Year\n%f = Codec\n%n = Tracknumber\n%t = Trackname\n%va = Various Artist\n")
		answer = get_answer(_("New %s naming scheme (q to quit) : ") % [variable], "open", "%f/%a (%y) %b/%n - %t") 
		if answer !=_('q')
			if variable == 'normal'
				puts _("An example filename is now:\n\n\t%s") % [get_example_filename_normal(@settings['basedir'], answer)]
				@settings['naming_normal'] = answer
			else 
				puts _("An example filename is now:\n\n\t%s") % [get_example_filename_various(@settings['basedir'], answer)]
				@settings['naming_various'] = answer
			end
		end
	end
	
	def get_answer(question, answer, default)
		succes = false
		while !succes 
			if answer == "yes"
				answers = [_("yes"), _("y"), _("no"), _("n")]
				STDOUT.print(question + " [#{default}] ")
				input = STDIN.gets.strip
				if input == '' ; input = default end
				if answers.include?(input)
					if input == _('y') || input == _("yes") ; return true else return false end
				else puts _("Please answer yes or no") end
			elsif answer == "open"
				STDOUT.print(question + " [#{default}] ")
				input = STDIN.gets.strip
				if input == '' ; return default else return input end
			elsif answer == "number"
				STDOUT.print(question + " [#{default}] ")
				input = STDIN.gets.strip
				#convert the answer to an integer value, if input is a text it will be 0.
				#make sure that the valid answer of 0 is respected though
				if input.to_i == 0 && input != "0" ; return default else return input.to_i end
			else puts _("We should never get here") ; puts _("answer = %s, question = %s (error)") % [answer, question]
 			end
		end
	end

	def get_cd_info
		@settings['cd'] = Disc.new(@settings, self) # Analyze the TOC of disc in drive
		if @settings['cd'].audiotracks != 0 # a disc is found
			puts _("Audio-disc found, number of tracks : %s, total playlength : %s") % [@settings['cd'].audiotracks, @settings['cd'].playtime]
			if @settings['freedb'] #freedb enabled?
				puts _("Fetching freedb info...")
				handleFreedb()
			else
				showFreedb()
			end
		else 
			puts @settings['cd'].error
			edit_settings()
		end
	end

	#Fetch the cddb info if user wants to
	def handleFreedb(choice = false)
		if choice == false
			@settings['cd'].md.freedb(@settings, @settings['first_hit'])
		else
			@settings['cd'].md.freedbChoice(choice)
		end

		status = @settings['cd'].md.status
		
		if status == true #success
			showFreedb()
		elsif status[0] == "choices"
			chooseFreedb(status[1])
		elsif status[0] == "noMatches"
			update("error", status[1]) # display the warning, but continue anyway
			showFreedb()
		elsif status[0] == "networkDown" || status[0] == "unknownReturnCode" || status[0] == "NoAudioDisc"
			update("error", status[1])
		else
			puts "Unknown error with Metadata class."
		end
	end

	def chooseFreedb(choices)
		puts _("Freedb reported multiple possibilities.")
		if @options.defaults == true
			puts _("The first freedb option is automatically selected (no questions allowed)")
			handleFreedb(0)
		else
			choices.each_index{|index| puts "#{index + 1}) #{choices[index]}"}
			choice = get_answer(_("Please type the number of the one you prefer? : "), "number", 1)
			handleFreedb(choice - 1)
		end
	end

	def showFreedb()
		puts ""
		puts _("FREEDB INFO\n\n")
		puts _("DISC INFO")
		print _("Artist:") ; print " #{@settings['cd'].md.artist}\n"
		print _("Album:") ; print " #{@settings['cd'].md.album}\n"
		print _("Genre:") ; print " #{@settings['cd'].md.genre}\n"
		print _("Year:") ; print " #{@settings['cd'].md.year}\n"
		puts ""
		puts _("TRACK INFO")
		
		showTracks()
		if @options.defaults
			prepareRip()
		else
			showFreedbOptions()
		end
	end

	def showTracks()
		@settings['cd'].audiotracks.times do |index|
			trackname = @settings['cd'].md.tracklist[index]
			if not @settings['cd'].md.varArtists.empty?
				trackname = "#{@settings['cd'].md.varArtists[index]} - #{trackname}"
			end

			puts "#{index +1 }) #{trackname}"
		end
	end

	def showFreedbOptions()
		puts ""
		puts _("What would you like to do?")
		puts ""
		puts _("1) Select the tracks to rip")
		puts _("2) Edit the disc info")
		puts _("3) Edit the track info")
		puts _("4) Cancel the rip and eject the disc")
		puts ""

		answer = get_answer(_("Please enter the number of your choice: "), "number", 1)
		if answer == 1 ; prepareRip()
		elsif answer == 2 ; editDiscInfo()
		elsif answer == 3 ; editTrackInfo()
		else cancelRip()
		end
	end

	def editDiscInfo()
		puts "1) " + _("Artist:") + " #{@settings['cd'].md.artist}"
		puts "2) " + _("Album:") + " #{@settings['cd'].md.album}"
		puts "3) " + _("Genre:") + " #{@settings['cd'].md.genre}"
		puts "4) " + _("Year:") + " #{@settings['cd'].md.year}"
		
		if @settings['cd'].md.varArtists.empty?
			puts "5) " + _("Mark disc as various artist")
		else
			puts "5) " + _("Mark disc as single artist")
		end

		puts "99) " + _("Finished editing disc info\n\n")
		
		while true
			answer = get_answer(_("Please enter the number you'd like to edit: "), "number", 99)
			if answer == 1 ; @settings['cd'].md.artist = get_answer(_("Artist : "), "open", @settings['cd'].md.artist)
			elsif answer == 2 ; @settings['cd'].md.album = get_answer(_("Album : "), "open", @settings['cd'].md.album)
			elsif answer == 3 ; @settings['cd'].md.genre = get_answer(_("Genre : "), "open", @settings['cd'].md.genre)
			elsif answer == 4 ; @settings['cd'].md.year = get_answer(_("Year : "), "open", @settings['cd'].md.year)
			elsif answer == 5 ; if @settings['cd'].md.varArtists.empty? ; setVarArtist() else unsetVarArtist() end
			elsif answer == 99 ; break
			end
		end

		showFreedb()
	end

	def setVarArtist #Fill with unknown if the artistfield is not there
		@settings['cd'].audiotracks.times do |time|
			if @settings['cd'].md.varArtists[time] == nil
				@settings['cd'].md.varArtists[time] = _('Unknown')
			end
		end
	end
	
	def unsetVarArtist #Reset the varArtist field
		@settings['cd'].md.undoVarArtist()
	end

	def editTrackInfo()
		showTracks()
		puts ""
		puts "99) " + _("Finished editing track info\n\n")

		while true
			answer = get_answer(_("Please enter the number you'd like to edit: "), "number", 99)
		
			if answer == 99 ; break
			elsif (answer.to_i > 0 && answer.to_i <= @settings['cd'].audiotracks)
				@settings['cd'].md.tracklist[answer - 1] = get_answer("Track #{answer} : ", "open", @settings['cd'].md.tracklist[answer - 1])
				if not @settings['cd'].md.varArtists.empty?
					@settings['cd'].md.varArtists[answer - 1] = get_answer("Artist for Track #{answer} : ", "open", @settings['cd'].md.varArtists[answer - 1])
				end
			else
				puts _("This is not a valid number. Try again")
			end
		end

		showFreedb()
	end

	def cancelRip()
		puts _("Rip is canceled, exiting...")
		eject(@settings['cd'].cdrom)
		exit()
	end

	def prepareRip()
		tracklist() # Which tracks should be ripped?
		@rubyripper = Rubyripper.new(@settings, self) # starts some check if the settings are sane
		
		status = @rubyripper.settingsOk
		if status == true
			@rubyripper.startRip()
		else
			update(status[0], status[1])
		end
	end
	
	def dir_exists
		puts _("The output directory already exists. What would you like to do?")
		puts ""
		puts _("1) Auto rename the output directory")
		puts _("2) Overwrite the existing directory")
		puts _("3) Cancel the rip and eject the disc")
		puts ""

		answer = get_answer(_("Please enter the number of your choice: "), "number", 1)
		if answer == 1; @rubyripper.postfixDir() ; @rubyripper.startRip()
		elsif answer == 2; @rubyripper.overwriteDir() ; @rubyripper.startRip()
		else cancelRip()
		end
	end

	def update(modus, value=false)
		if modus == "ripping_progress"
			progress = "%.3g" % (value * 100)
			puts "Ripping progress (#{progress} %)"
		elsif modus == "encoding_progress"
			progress = "%.3g" % (value * 100)
			puts "Encoding progress (#{progress} %)"
		elsif modus == "log_change"
			print value
		elsif modus == "error"
			print value
			print "\n"
			if get_answer(_("Do you want to change your settings? (y/n) : "), "yes",_("y")) ; edit_settings() end
		elsif modus == "dir_exists"
			dir_exists()
		end
	end

	def tracklist # Fill @settings['tracksToRip']
		@settings['tracksToRip'] = Array.new
		@settings['cd'].audiotracks.times{|number| @settings['tracksToRip'] << number + 1} # Start with all tracks selected
		if @settings['image']
			@settings['tracksToRip'] = ["image"]
		elsif @options.defaults || get_answer(_("\nShould all tracks be ripped ? (y/n) "), "yes", _('y'))
			puts _("Tracks to rip are %s") % [@settings['tracksToRip'].join(" ")]
		else
			succes = false
			while !succes
				puts _("Current selection of tracks : %s") % [@settings['tracksToRip'].join(' ')]
				number = get_answer(_("Enter 1 for entering the tracknumbers you want to remove.\nEnter 2 for entering the tracks you want to keep.\nYour choice: "), "number", 1)
				if number == 1
					print _("Type the numbers of the tracks you want to remove and separate them with a space: ")
					answer = STDIN.gets.strip.split
					answer.each_index{|index| answer[index] = answer[index].to_i} #convert to integers
					@settings['tracksToRip'] -= answer # don't you just love ruby math? [1,2,3,4,5] - [3,4] = [1,2,5]
				elsif number == 2
					print _("Type the numbers of the tracks you want to keep and separate them with a space: ")
					answer = STDIN.gets.strip.split
					answer.each_index{|index| answer[index] = answer[index].to_i} #convert to integers
					remove = @settings['tracksToRip'] - answer # remove is inverted result -> which tracks you want to remove?
					@settings['tracksToRip'] -= remove # remove these
				else
					puts _("%s is not a valid number! Please enter 1 or 2!\n") % [number]
				end
				if number == 1 || number == 2
					puts _("Current selection of tracks : %s") % [@settings['tracksToRip'].join(' ')]
					succes = !get_answer(_("Do you want to make any changes? (y/n) : "), "yes", _("n"))
				end
			end
		end
	end
end	

Gui_CLI.new()
