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
		@finished = false
		@settings = $rr_defaultSettings
		if File.exist?(File.expand_path(@options.file))
			load_configfile()
			if @options.configure: edit_settings() end
		else
			edit_settings() # Always set up settings if no config file exists.
		end		
		get_cd_info()
	end

	def parse_options
		@options = OpenStruct.new
		@options.file = "~/.rubyripper/settings"
		@options.help = false
		@options.verbose = false
		@options.configure = false
		@options.all = false
		@options.help = false

		opts = OptionParser.new(banner = nil, width = 20, indent = ' ' * 2) do |opts|
			opts.on("-V", "--version", _("Show current version of rubyripper.")) do
				puts "Rubyripper version #{$rr_version}."
				exit()
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
			opts.on("-a", "--all", _("Rip all tracks. Skip any questions about track selection.")) do |a|
				@options.all = a
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

		if @options.help: exit end

		puts _("Verbose output specified.") if @options.verbose
		puts _("Configure option specified.") if @options.configure
		puts _("Rip all tracks specified.") if @options.all
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
		puts _("22) edit freedb data before ripping [%s]") % [@settings['edit'] ? '*' : ' ']
 		puts ""
		puts _("88) config file = %s") % [@options.file]
 		puts _("99) Don't change any setting")
 		puts ""
	end

	def edit_settings # depending on the input of the user as asked in show_settings(), change the setting
		show_settings()
		while (number = get_answer(_("Please type the number of the setting you wish to change : "), "number", 99)) != 99
			if number == 1 : set_codec('flac')
			elsif number == 2 : set_codec('vorbis')
			elsif number == 3 : set_codec('mp3')
			elsif number == 4 : if @settings['wav'] : puts _("wav disabled") ; @settings['wav'] = false else puts _("wav enabled") ; @settings['wav'] = true end
			elsif number == 5 : set_codec('other')
			elsif number == 6 : if @settings['playlist'] : puts _("playlist disabled") ; @settings['playlist'] = false else puts _("playlist enabled") ; @settings['playlist'] = true end
			elsif number == 7 : @settings['maxThreads'] = get_answer(_("How many encoding threads would you like? : "), "number", 1)
			elsif number == 8 : set_cdrom()
			elsif number == 9 : @settings['rippersettings'] = get_answer(_("Which options to pass to cdparanoia? : "), "open", "")
			elsif number == 10 : @settings['req_matches_all'] = get_answer(_("How many times must all chunks be matched? : "), "number", 2)
			elsif number == 11 : @settings['req_matches_errors'] = get_answer(_("How many times must erroneous chunks be matched? : "), "number", 3)
			elsif number == 12 : @settings['max_tries'] = get_answer(_("What should be the maximum number of tries? : "), "number", 5)
			elsif number == 13 : if @settings['eject'] : puts _("eject disabled") ; @settings['eject'] = false else puts _("eject enabled") ; @settings['eject'] = true end
			elsif number == 14 : @settings['basedir'] = get_answer(_("Please enter your directory for your encodings: "), "open", "")
			elsif number == 15 : setdir('normal')
			elsif number == 16 : setdir('various')
			elsif number == 17 : if @settings['freedb'] : puts _("freedb disabled") ; @settings['freedb'] = false else puts _("freedb enabled") ; @settings['freedb'] = true end
			elsif number == 18 : if @settings['first_hit'] : puts _("first hit disabled") ; @settings['first_hit'] = false else puts _("first hit enabled") ; @settings['first_hit'] = true end
			elsif number == 19 : @settings['site'] = get_answer(_("Freedb mirror: "), "open", "freedb.org")
			elsif number == 20 : @settings['username'] = get_answer(_("Username : "), "open", "anonymous")
			elsif number == 21 : @settings['hostname'] = get_answer(_("Hostname : "), "open", "my_secret.com")
			elsif number == 22 : if @settings['edit'] : puts _("freedb editing disabled") ; @settings['edit'] = false else puts _("freedb editing enabled") ; @settings['edit'] = true end 
			elsif number == 88 : @options.file = get_answer(_("Config file : "), "open", @options.file)
			else puts _("Number %s is not an option!\nPlease try again.") % [number]
			end
			puts ""
			show_settings()
		end
		save_configfile()
		unless get_answer(_("Do you want to continue with the program now? (y/n) : "), "yes", _("y")) : exit() end
	end
	
	def set_codec(codec) # little help function for edit_settings
		@settings[codec] = get_answer("Do you want to enable #{codec} encoding? (y/n) : ", "yes", _("y"))
		if @settings[codec]
			if get_answer(_("Do you want to change the encoding parameters for %s? (y/n) : ") % [codec], "yes", _("n"))
				if codec == 'other' : puts _("%a = artist, %b = album, %g = genre, %y = year, %t = trackname, %n = tracknumber, %i = inputfile, %o = outputfile (don't forget extension)") end
				@settings[codec + 'settings'] = get_answer(_("Encoding paramaters for %s : ") % [codec], "open", "")
			end
		end
	end
	
	def set_cdrom # little help function for edit_settings
		@settings['cdrom'] = get_answer(_("Cdrom device : "), "open", cdrom_drive())
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

	def load_configfile # load config file
		if File.exist?(File.expand_path(@options.file))
			file = File.new(File.expand_path(@options.file),'r')
			while line = file.gets
				key, value = line.split('=', 2)
				value.rstrip! # remove the trailing newline character
				if value == "false" : value = false # replace the string with a bool
				elsif value == "true" : value = true  # replace the string with a bool
				elsif value == "''" : value = '' #replace a string that contains two quotes with an empty string
				elsif value[0,1] == "#" : next #name of previous instances should not be loaded
				elsif value.to_i > 0 || value == '0' : value = value.to_i
				end
				@settings[key] = value
			end
			file.close()
		end
	end
	
	def save_configfile # save config file
		if not File.directory?(dirname = File.join(ENV['HOME'], '.rubyripper')) : Dir.mkdir(dirname) end
		file = File.new(File.expand_path(@options.file), 'w')
		@settings.each do |key, value|
			file.puts "#{key}=#{value}"
		end
		file.close()
	end
	
	def get_answer(question, answer, default)
		succes = false
		while !succes 
			if answer == "yes"
				answers = [_("yes"), _("y"), _("no"), _("n")]
				STDOUT.print(question + " [#{default}] ")
				input = STDIN.gets.strip
				if input == '' : input = default end
				if answers.include?(input)
					if input == _('y') || input == _("yes") : return true else return false end
				else puts _("Please answer yes or no") end
			elsif answer == "open"
				STDOUT.print(question + " [#{default}] ")
				input = STDIN.gets.strip
				if input == '' : return default else return input end
			elsif answer == "number"
				STDOUT.print(question + " [#{default}] ")
				input = STDIN.gets.strip.to_i #convert the answer to an integer value, if input is a text it will be 0.
				if input == 0 : return default else return input end
			else puts _("We should never get here") ; puts _("answer = %s, question = %s (error)") % [answer, question]
 			end
		end
	end

	def get_cd_info
		@settings['cd'] = Disc.new(@settings['cdrom'], @settings['freedb'], self, @settings['verbose']) # Analyze the TOC of disc in drive
		if @settings['cd'].audiotracks != 0 # a disc is found
			puts _("Audio-disc found, number of tracks : %s, total playlength : %s") % [@settings['cd'].audiotracks, @settings['cd'].playtime]
			if @settings['freedb'] #freedb enabled?
				puts _("Fetching freedb info...")
				@settings['cd'].md.freedb(@settings, @settings['first_hit'])
			else
				freedb_finished()
			end
		else 
			puts @settings['cd'].error
			edit_settings()
		end
	end

	def freedb_finished #got the signal that all the metadata info is ready for processing
		if @settings['edit'] : edit_freedb() else show_freedb() end
		tracklist() # Which tracks should be ripped?
		@rubyripper = Rubyripper.new(@settings, self) # starts some check if the settings are sane
		puts "Now here, class = #{@rubyripper.class}"
		if @rubyripper.settings_ok : start() end
	end
	
	def choose_freedb(choices) #callback function initiated by rr_lib.rb via our update function
		puts _("Freedb reported multiple possibilities.")
		choices.each_index{|index| puts "#{index + 1}) #{choices[index]}"}
		choice = get_answer(_("Please type the number of the one you prefer? : "), "number", 1)
		@settings['cd'].md.freedbChoice(choice - 1)
	end

	def show_freedb(edit = false) # leave the letters and numbers away if edit mode == false
		puts ""
		puts _("FREEDB INFO")
		puts _("#{"a) " if edit}Artist : %s") % [@settings['cd'].md.artist]
		puts _("#{"b) " if edit}Album : %s") % [@settings['cd'].md.album]
		puts _("#{"c) " if edit}Genre : %s") % [@settings['cd'].md.genre]
		puts _("#{"d) " if edit}Year : %s") % [@settings['cd'].md.year]
		puts ""
		@settings['cd'].audiotracks.times do |index|
			puts _("%sTrack %s : %s")  % [if edit : "#{index + 1}) " end, index + 1, @settings['cd'].md.tracklist[index]]
		end
		puts ""
	end
	
	def edit_freedb
		show_freedb(edit = true)
		puts _("99) Don't change any setting")
 		puts ""
		while (answer = get_answer(_("Please type the letter or number of the setting you wish to change : "), "open", "99")) != "99"
			if answer == "a" : @settings['cd'].md.artist = get_answer(_("Artist : "), "open", @settings['cd'].md.artist)
			elsif answer == "b" : @settings['cd'].md.album = get_answer(_("Album : "), "open", @settings['cd'].md.album)
			elsif answer == "c" : @settings['cd'].md.genre = get_answer(_("Genre : "), "open", @settings['cd'].md.genre)
			elsif answer == "d" : @settings['cd'].md.year = get_answer(_("Year : "), "open", @settings['cd'].md.year)
			else
				if answer.to_i > 0 && answer.to_i <= @settings['cd'].audiotracks #Check if tracknumber is in valid range
					@settings['cd'].md.tracklist[answer.to_i - 1] = get_answer("Track #{answer.to_i} : ", "open", @settings['cd'].md.tracklist[answer.to_i - 1])
				else
					puts _("This is not a valid number. Try again")
				end
			end	
			show_freedb(edit = true)
		end
	end

	def dir_exists
		puts _("The output directory already exists. What would you like to do?")
		puts ""
		puts _("1) Auto rename the output directory")
		puts _("2) Overwrite the existing directory")
		puts _("3) Cancel the rip")
		puts _("4) Cancel the rip and eject the disc")
		puts ""
		answer = get_answer(_("Please enter the number of your choice: "), "number", 1)
		if answer == 1: @rubyripper.postfix_dir() ; start()
		elsif answer == 2: @rubyripper.overwrite_dir() ; start()
		else
			puts _("Rip is canceled, exiting...")
			eject(@settings['cd'].cdrom) if answer == 4
			exit()
		end
	end

	def start
		@rubyripper.start_rip()
		while @finished == false
			sleep(1) #loop until the finished signal is given. This is not ideal, but apparently the program gets terminated otherwise.
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
			if get_answer(_("Do you want to change your settings? (y/n) : "), "yes",_("y")) : edit_settings() end
		elsif modus == "cddb_hit" && value == false #final values freedb
			freedb_finished
		elsif modus == "cddb_hit" && value != false #multiple freedb hits
			choose_freedb(value)
		elsif modus == "dir_exists"
			dir_exists()
		elsif modus == "finished"
			@finished = true
		end
	end

	def tracklist # Fill @settings['tracksToRip']
		@settings['tracksToRip'] = Array.new
		@settings['cd'].audiotracks.times{|number| @settings['tracksToRip'] << number + 1} # Start with all tracks selected
		if @options.all || get_answer(_("\nShould all tracks be ripped ? (y/n) "), "yes", _('y'))
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
