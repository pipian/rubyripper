#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007  Bouke Woudstra (rubyripperdev@gmail.com)
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

#ensure translation is working before actually installing
LOCALE=[ENV['PWD'] + "/locale", "/usr/local/share/locale"]
LOCALE.each{|dir| if File.directory?(dir) ; ENV['GETTEXT_PATH'] = dir ; break end}

$rr_version = '0.6.0' #application wide setting

begin
	require 'gettext'
	include GetText
	bindtextdomain("rubyripper")
rescue LoadError
	puts "ruby-gettext is not found. Translations are disabled!"
	def _(txt)
		txt
	end
end

Thread.abort_on_exception = true

require 'monitor' #help library for threaded applications
require 'yaml' #help library to save data structures into files
require 'fileutils' #help library for moving files

def installed(filename) # a help function to check if an application is installed
	ENV['PATH'].split(':').each do |dir|
		if File.exist?(dir + '/' + filename) ; return true end
	end
	if File.exist?(filename) ; return true else return false end #it can also be in current working dir
end

if not installed('cdparanoia')
	puts "Cdparanoia not found on your system.\nThis is required to run rubyripper. Exiting..."
	exit()
end

def get_example_filename_normal(basedir, layout) #separate function to make it faster
	filename = File.join(basedir, layout)
	filename = File.expand_path(filename)
	filename = _("Example filename: %s.ext") % [filename]
	{'%a' => 'Judas Priest', '%b' => 'Sin After Sin', '%f' => 'codec', '%g' => 'Rock', '%y' => '1977', '%n' =>'01', '%t' => 'Sinner', '%i' =>'inputfile', '%o' => 'outputfile'}.each{|key, value| filename.gsub!(key,value)}
	return filename
end

def get_example_filename_various(basedir, layout) #separate function to make it faster
	filename = File.join(basedir, layout)
	filename = File.expand_path(filename)
	filename = _("Example filename: %s.ext") % [filename]
	{'%va' => 'Various Artists', '%b' => 'TMF Rockzone', '%f' => 'codec', '%g' => "Rock", '%y' => '1999', '%n' => '01', '%a' => 'Kid Rock', '%t' => 'Cowboy'}.each{|key, value| filename.gsub!(key,value)}
	return filename
end

def eject(cdrom)
	Thread.new do
	 	if installed('eject') ; `eject #{cdrom}`
		elsif installed('diskutil'); `diskutil eject #{cdrom}` #Mac users don't got eject, but diskutil
		else puts _("No eject utility found!")
		end
	end
end

class Settings
attr_reader :settings, :configFound
	def initialize(configFile = false)
		@settings = Hash.new()
		@configFound = false
		@defaultSettings = {"flac" => false, #boolean 
			"flacsettings" => "--best -V", #string, passed to flac
			"vorbis" => true, #boolean
			"vorbissettings" => "-q 4", #string, passed to vorbis
			"mp3" => false, #boolean
			"mp3settings" => "-V 3 --id3v2-only", #string, passed to lame
			"wav" => false, #boolean
			"other" => false, #boolean, any other codec
			"othersettings" => '', #string, the complete command
			"playlist" => true, #boolean
			"cdrom" => cdrom_drive(), #string
			"offset" => 0, #integer
			"maxThreads" => 2, #integer, number of encoding proces while ripping
			"rippersettings" => '', #string, passed to cdparanoia
			"max_tries" => 5, #integer, #tries before giving up correcting
			'basedir' => '~/', #string, where to store your new rips?
			'naming_normal' => '%f/%a (%y) %b/%n - %t', #string, normal discs
			'naming_various' => '%f/%va (%y) %b/%n - %a - %t', #string various
			'naming_image' => '%f/%a (%y) %b/%a - %b (%y)', #string, image
			"verbose" => false, #boolean, extra verbose info shown in terminal
			"debug" => true, #boolean, extra debug info shown in terminal
			"eject" => true, #boolean, open up the tray when finished
			'ripHiddenAudio' => true, #boolean, rip part before track 1
			'minLengthHiddenTrack' => 2, #integer, min. length hidden track
			"req_matches_errors" => 2, # #integer, matches when errors detected
			"req_matches_all" => 2,  #integer, #matches when no errors detected
			"site" => "http://freedb.freedb.org/~cddb/cddb.cgi", #string, freedb site
			"username" => "anonymous", #string, user name freedb
			"hostname" => "my_secret.com", #string, hostname freedb
			"first_hit" => true, #boolean, always choose 1st option
			"freedb" => true, #boolean, enable freedb
			"editor" => editor(), #string, default editor
			"filemanager" => filemanager(), #string, default file manager
			"browser" => browser(), #string, default browser
			"no_log" =>false, #boolean, delete log if no errors?
			"create_cue" => true, #boolean, create cuesheet
			"image" => false, #boolean, save to single file
			'normalize' => false, #boolean, normalize volume?
			'gain' => "album", #string, gain mode
			'gainTagsOnly' => false, #string, not actually modify audio
			'noSpaces' => false, #boolean, replace spaces with underscores
			'noCapitals' => false, #boolean, replace uppercase with lowercase
			'pregaps' => "prepend", #string, way to handle pregaps
			'preEmphasis' => 'cue' #string, way to handle pre-emphasis
		}
		setFileLocation(configFile)
		migrationCheck()
		loadSettings()
	end

	# set all file locations
	def setFileLocation(configFile)
		if configFile == false
			dir = ENV['XDG_CONFIG_HOME'] || File.join(ENV['HOME'], '.config')
			@configFile = File.join(dir, 'rubyripper/settings')
		else
			@configFile = File.expand_path(configFile)
		end

		dir = ENV['XDG_CACHE_HOME'] || File.join(ENV['HOME'], '.cache')
		@cacheFile = File.join(dir, 'rubyripper/freedb.yaml')

		#store the location in the settings for use later on
		@defaultSettings['freedbCache'] = @cacheFile

		createDirs(File.dirname(@configFile))
		createDirs(File.dirname(@cacheFile))
	end

	# help function to create dirs
	def createDirs(dirName)
		if !File.directory?(File.dirname(dirName))
			createDirs(File.dirname(dirName))
		end
		Dir.mkdir(dirName) if !File.directory?(dirName)
	end

	# check for existing configs in old directories and move them
	# to the standard directories conform the freedesktop.org spec
	def migrationCheck()
		oldDir = File.join(ENV['HOME'], '.rubyripper')
		if File.directory?(oldDir)
			puts "Auto migrating to new file locations..."
			oldConfig = File.join(ENV['HOME'], '.rubyripper/settings')
			oldCache = File.join(ENV['HOME'], '.rubyripper/freedb.yaml')
			moveFiles(oldConfig, oldCache)
			deleteOldDir(oldDir)
		end

		# clean up a very old config file
		if File.exists?(oldFile = File.join(ENV['HOME'], '.rubyripper_settings'))
			FileUtils.rm(oldFile)
		end
	end

	# help function to move the files
	def moveFiles(oldConfig, oldCache)
		if File.exists?(oldConfig)
			FileUtils.mv(oldConfig, @configFile)
			puts "New location of config file: #{@configFile}"
		end

		if File.exists?(oldCache)
			FileUtils.mv(oldCache, @cacheFile)
			puts "New location of freedb file: #{@cacheFile}"
		end
	end

	# help function to remove the old dir
	def deleteOldDir(oldDir)
		if File.symlink?(oldDir)
			File.delete(oldDir)
		elsif Dir.entries(oldDir).size > 2 # some leftover file(s) remain
			puts "#{oldDir} could not be removed: it's not empty!"
		else
			Dir.delete(oldDir)
		end
		puts "Auto migration finished succesfull."
	end

	# first load defaults, then overwrite the values found in the config file
	def loadSettings()
		@settings = @defaultSettings.dup

		if File.exist?(@configFile)
			@configFound = true
			file = File.new(@configFile,'r')
			while line = file.gets
				key, value = line.split('=', 2)
				# remove the trailing newline character
				value.rstrip!
				# replace the strings false/true with a bool
				if value == "false" ; value = false 
				elsif value == "true" ; value = true
				# replace two quotes with an empty string
				elsif value == "''" ; value = ''
				# replace an integer string with an integer 
				elsif value.to_i > 0 || value == '0' ; value = value.to_i
				end
				# only load a setting that is included in the default
				if @defaultSettings.key?(key) ; @settings[key] = value end
			end
			file.close()
		end
	end

	# save the settings to the config file
	def save(settings)
		file = File.new(@configFile, 'w')
		settings.each do |key, value|
			file.puts "#{key}=#{value}" if @defaultSettings.include?(key)
		end
		file.close()
	end

	# determine default drive
	def cdrom_drive #default values for cdrom drives under differenty os'es
		drive = 'Unknown!'
		system = RUBY_PLATFORM
		if system.include?('openbsd')
			drive = '/dev/cd0c' # as provided in issue 324
		elsif system.include?('linux') || system.include?('bsd')
			drive = '/dev/cdrom'
		elsif system.include?('darwin')
			drive = '/dev/disk1'
		end
		return drive
	end

	# determine default file manager
	def filemanager #look for default filemanager
		if ENV['DESKTOP_SESSION'] == 'kde' && installed('dolphin')
			return 'dolphin'
		elsif ENV['DESKTOP_SESSION'] == 'kde' && installed('konqueror')
			return 'konqueror'
		elsif installed('thunar')
			return 'thunar' #Xfce4 filemanager
		elsif installed('nautilus')
			return 'nautilus --no-desktop' #Gnome filemanager
		else
			return 'echo'
		end
	end

	# determine default editor
	def editor # look for default editor
		if ENV['DESKTOP_SESSION'] == 'kde' && installed('kwrite')
			return 'kwrite'
		elsif installed('mousepad')
			return 'mousepad' #Xfce4 editor
		elsif installed('gedit')
			return 'gedit' #Gnome editor
		elsif ENV.key?('EDITOR')
			return ENV['EDITOR']
		else	
			return 'echo'
		end
	end

	#determine default browser
	def browser
		if installed('chromium')
			return 'chromium'
		elsif ENV['DESKTOP_SESSION'] == 'kde' && installed('konqueror')
			return 'konqueror'
		elsif installed('epiphany')
			return 'epiphany'
		elsif installed('firefox')
			return 'firefox'
		elsif installed('opera')
			return 'opera'
		elsif ENV.key?('BROWSER')
			return ENV['BROWSER']
		else
			return 'echo'
		end
	end
end

class Gui_support
attr_reader :rippingErrors, :encodingErrors, :short_summary
attr_writer :encodingErrors

	def initialize(settings) #gui is an instance of the graphical user interface used
		@settings = settings
		createLog()
		
		@problem_tracks = Hash.new # key = tracknumber, value = new dictionary with key = seconds_chunk, value = [amount_of_chunks, trials_needed]
		@not_corrected_tracks = Array.new # Array of tracks that weren't corrected within the maximum amount of trials set by the user
		@ripping_progress = 0.0
		@encoding_progress = 0.0
		@encodingErrors = false
		@rippingErrors = false
		@short_summary = _("Artist : %s\nAlbum: %s\n") % [@settings['cd'].md.artist, @settings['cd'].md.album]
		addLog(_("This log is created by Rubyripper, version %s\n") % [$rr_version])
		addLog(_("Website: http://code.google.com/p/rubyripper\n\n"))
	end

	def createLog
		@logfiles = Array.new
		['flac', 'vorbis', 'mp3', 'wav', 'other'].each do |codec|
			if @settings[codec]
				@logfiles << File.open(@settings['Out'].getLogFile(codec), 'a')
			end
		end
	end
	
	# update the ripping percentage of the gui
	def ripPerc(new_value, calling_function = false) #new_value = float, 1 = 100%
		new_value <= 1.0 ? @ripping_progress = new_value : @ripping_progress = 1.0
		@settings['instance'].update("ripping_progress", @ripping_progress)
	end
	
	# update the encoding percentage of the gui
	def encPerc(new_value, calling_function = false) #new_value = float, 1 = 100%
		new_value <= 1.0 ? @encoding_progress = new_value : @encoding_progress = 1.0
		@settings['instance'].update("encoding_progress", @encoding_progress)
	end
	
	# Add a message to the logging file + update the gui
	def add(message, calling_function = false)
		@logfiles.each{|logfile| logfile.print(message); logfile.flush()} # Append the messages to the logfiles
		@settings['instance'].update("log_change", message)
	end
	
	# Add a message to the logging file
	def addLog(message, summary = false)
		@logfiles.each{|logfile| logfile.print(message); logfile.flush()} # Append the messages to the logfiles
		if summary ; @short_summary += message end
	end
	
	def mismatch(track, trial, indexes_with_errors, size, length)
		if !@problem_tracks.key?(track) #First time we encounter this track (Secure_rip->analyzeFiles() )
			@problem_tracks[track] = Hash.new # create the Hash for the track
			indexes_with_errors.each do |index_of_chunk|
				seconds = index_of_chunk / 176400 # position of chunk rounded in seconds, each second = 176400 bytes
				if !@problem_tracks[track].key?(seconds)
					@problem_tracks[track][seconds] = [1, trial] # different_chunks, trial. First time we encounter this position, so different_chunks = 1
				else
					@problem_tracks[track][seconds][0] += 1 # one more chunk at the same second
				end
			end
		else
			indexes_with_errors.each do |index_of_chunk|
				seconds = index_of_chunk / 176400 # position of chunk rounded in seconds, each second = 176400 bytes
				@problem_tracks[track][seconds][1] = trial #Update the amount of trials needed
			end
		end
		if trial == 0; @not_corrected_tracks << track end #Reached maxtries and still got errors
	end
	
	def summary(matches_all, matches_errors, maxtries) #Give an overview of errors
		if @encodingErrors ; addLog(_("\nWARNING: ENCODING ERRORS WERE DETECTED\n"), true) end
		addLog(_("\nRIPPING SUMMARY\n\n"), true)
		
		addLog(_("All chunks were tried to match at least %s times.\n") % [matches_all], true)
		if matches_all != matches_errors; addLog(_("Chunks that differed after %s trials,\nwere tried to match %s times.\n") % [matches_all, matches_errors], true) end

		if @problem_tracks.empty?
 			addLog(_("None of the tracks gave any problems\n"), true)
 		elsif @not_corrected_tracks.size != 0
 			addLog(_("Some track(s) could NOT be corrected within the maximum amount of trials\n"), true)
 			@not_corrected_tracks.each do |track|
				@rippingErrors = true
				addLog(_("Track %s could NOT be corrected completely\n") % [track], true)
			end
 		else
 			addLog(_("Some track(s) needed correction,but could\nbe corrected within the maximum amount of trials\n"), true)
 		end

 		if !@problem_tracks.empty? # At least some correction was necessary
			position_analyse(matches_errors, maxtries)
			@short_summary += _("The exact positions of the suspicious chunks\ncan be found in the ripping log\n")
		end
		@logfiles.each{|logfile| logfile.close} #close all the files
 	end
 		
 	def position_analyse(matches_errors, maxtries) # Give an overview of suspicion position in the logfile
		addLog(_("\nSUSPICIOUS POSITION ANALYSIS\n\n"))
		addLog(_("Since there are 75 chunks per second, after making the notion of the\n"))
		addLog(_("suspicious position, the amount of initially mismatched chunks for\nthat position is shown.\n\n"))
		@problem_tracks.keys.sort.each do |track| # For each track show the position of the files, how many chunks of that position and amount of trials needed to solve
			addLog(_("TRACK %s\n") % [track])
			@problem_tracks[track].keys.sort.each do |length| #length = total seconds of suspicious position
				minutes = length / 60 # ruby math -> 70 / 60 = 1 (how many times does 60 fit in 70)
				seconds = length % 60 # ruby math -> 70 % 60 = 10 (leftover)
				if @problem_tracks[track][length][1] != 0
					addLog(_("\tSuspicious position : %s:%s (%s x) (CORRECTED at trial %s)\n") % [sprintf("%02d", minutes), sprintf("%02d", seconds), @problem_tracks[track][length][0], @problem_tracks[track][length][1] + 1])
				else # Position could not be corrected
					addLog(_("\tSuspicious position : %s:%s (%sx) (COULD NOT BE CORRECTED)\n") % [ sprintf("%02d", minutes), sprintf("%02d", seconds), @problem_tracks[track][length][0]])
				end
			end
		end
	end
	
	# delete the logfiles if no errors occured
	def delLog
		if @problem_tracks.empty? && !@encodingErrors
			@logfiles.each{|logfile| File.delete(logfile.path)}
		end
	end
end

class Disc
attr_reader :cdrom, :multipleDriveSupport, :audiotracks, :devicename,
:playtime, :freedbString, :oldFreedbString, :totalSectors, :md, :error,
:discId, :toc, :tocStarted, :tocFinished

	def initialize(settings, gui=false, oldFreedbString = '', test = false)
		@settings = settings
		@cdrom = @settings['cdrom']
		@freedb = @settings['freedb']
		@verbose = @settings['verbose']
		@gui = @settings['instance']

		@oldFreedbString = oldFreedbString #if new disc is the same, later on force a connection with the freedb server
		setVariables()
		if audioDisc()
			getDiscInfo()
			analyzeTOC() #table of contents
			@md = Metadata.new(self, @settings)
			prepareToc() unless test == true # use help of cdrdao to get info about pregaps etcetera
		end
	end

	def setVariables
		@multipleDriveSupport = true #not always the case on MacOS's cdparanoia
		
		@audiotracks = 0
		@lengthSector = Hash.new
		@startSector = Hash.new
		@lengthText = Hash.new
		@devicename = _("Unknown drive")
		@playtime = '00:00'

		@firstAudioTrack = 1 # some discs (games for instance) start with a data part
		@datatrack = false
		@freedbString = ''
		@discId = ''
		
		@totalSectors = 0
		
		@error = '' #set to the error messsage

		@toc = nil # instance of the AdvancedToc class
		@tocStarted = false # keeps track if the toc class is ever created
		@tocFinished = false
		@cdrdaoThread = nil # to later synchronize
		@cue = nil # instance of the Cuesheet class
	end

	# use cdrdao to scan for exact pregaps, hidden tracks, pre_emphasis
	def prepareToc
		if @settings['create_cue'] && installed('cdrdao')
			@cdrdaoThread = Thread.new{advancedToc()}
		end

		if @settings['create_cue'] && !installed('cdrdao')
			puts "Cdrdao not found. Advanced TOC analysis / cuesheet is skipped."
			@settings['create_cue'] = false # for further assumptions later on
		end
	end

	# start the Advanced toc instance
	def advancedToc
		@tocStarted = true
		@toc = AdvancedToc.new(@settings)
	end

	# update the Disc class with actual settings and make a cuesheet
	def updateSettings(settings)
		@settings = settings
		
		# user may have enabled cuesheet after the disc was scanned
		# @toc is still nil because the class isn't finished yet
		prepareToc() if @tocStarted == false
		
		# if the scanning thread is still active, wait for it to finish
		@cdrdaoThread.join() if @cdrdaoThread != nil
		
		# update the length of the sectors + the start of the tracks if we're prepending the gaps
		# also for the image since this is more easy with the cuesheet handling
		if @settings['pregaps'] == "prepend" || @settings['image']
			prependGaps()
		end
		
		# only make a cuesheet when the toc class is there
		@cue = Cuesheet.new(@settings, @toc) if @toc != nil
	end

	# prepend the gaps, so rewrite the toc info
	# notice that cdparanoia appends by default
	def prependGaps
		(2..@audiotracks).each do |track|
			pregap = @toc.getPregap(track)
			@lengthSector[track - 1] -= pregap
			@startSector[track] -= pregap
			@lengthSector[track] += pregap
		end
			             
		if @settings['debug']
			puts "Debug info: gaps are now prepended"
			puts "Startsector\tLengthsector"
			(1..@audiotracks).each do |track|
				puts "#{@startSector[track]}\t#{@lengthSector[track]}"
			end
		end             
	end

	def audioDisc
		unless checkDevice() #check if the cdrom device is real and has permissions right
			return false
		end

		@query = `cdparanoia -d #{@cdrom} -vQ 2>&1`
		
		unless genericDevice() #check permission of generic device if it exists
			return false
		end

		if $?.success? ; return true end #cdparanoia returned no problems
		
		if @query.include?("Unable to open disc")
			@query = false
			@error = _("No disc found in drive %s.\n\n"\
			"Please put an audio disc in first...") %[@cdrom]
			return false
		end

		if @query.include?('USAGE')
			if @verbose
				puts _("Perhaps cdparanoia doesn't support the drive parameter.\n Will retry with default drive")
			end
			@query = `cdparanoia -vQ 2>&1`
			if $?.success?
				@multipleDriveSupport = false
				return true
			else
				return false
			end
		end
	end
	
	def checkDevice
		while File.symlink?(@cdrom) #find the name of the device, not the symlink
			link = File.readlink(@cdrom)
			if (link.include?('..') || !link.include?('/'))
				@cdrom = File.expand_path(File.join(File.dirname(@cdrom), link))
			else
				@cdrom = link
			end
		end
		
		unless File.blockdev?(@cdrom) #is it a real device?
			@error = _("Cdrom drive %s does not exist on your system!\n"\
			"Please configure your cdrom drive first.") % [@cdrom]
			@query = false
			return false
		end
			
		unless (File.readable?(@cdrom) && File.writable?(@cdrom))
			@error = _("You don't have read and write permission\n"\
			"for device %s on your system! These permissions are\n"\
			"necessary for cdparanoia to scan your drive.\n\n%s\n"\
			"You might want to add yourself to the necessary group in /etc/group")\
			%[@cdrom, "ls -l shows #{`ls -l #{@cdrom}`}"]
			return false
		end
		
		return true
	end
	
	def genericDevice #looking for the character device (sata/scsi-only)
		device = nil
		if @query.include?('generic device: ')
			@query.each do |line|
				if line =~ /generic device: /
					device = $'.strip() #the part after the match
					break #end the loop
				end
			end
		else
			return true
		end
		
		unless ((File.chardev?(device) || File.blockdev?(device)) && File.readable?(device) && File.writable?(device))
			permission = nil
			if File.chardev?(device) && installed('ls')
				permission = `ls -l #{device}`
			end
			
			@error = _("You don't have read and write permission\n"\
			"for device %s on your system! These permissions are\n"\
			"necessary for cdparanoia to scan your drive.\n\n%s\n"\
			"You might want to add yourself to the necessary group in /etc/group")\
			%[device, "#{if permission ; "ls -l shows #{permission}" end}"]
			
			return false
		end
		
		return true
	end
	
	def getDiscInfo
		@query.split("\n").each do |line|
			if line[0,5] =~ /\s+\d+\./
				@audiotracks += 1
				tracknumber, lengthSector, lengthText, startSector = line.split
				@firstAudioTrack = tracknumber[0..-2].to_i if @audiotracks == 1
				@lengthSector[@audiotracks] = lengthSector.to_i
				@startSector[@audiotracks] = startSector.to_i
				@lengthText[@audiotracks] = lengthText
			elsif line =~ /CDROM\D*:/
				@devicename = $'.strip()
			elsif line[0,5] == "TOTAL"
				@playtime = line.split()[2][1,5]
			end
		end
		
		if @freedb ; getFreedbString end
		@query = false
	end

	def getFreedbString
		if installed('discid')
			if RUBY_PLATFORM.include?('darwin') ; `diskutil unmount #{@cdrom}` end
			@freedbString = `discid #{@cdrom}`
			if RUBY_PLATFORM.include?('darwin') ; `diskutil mount #{@cdrom}` end
		elsif installed('cd-discid') # if no discid exists, try cd-discid
			@freedbString = `cd-discid #{@cdrom}`
		else # if both do not exist generate it ourselves (less foolproof)
			puts _("warning: discid or cd-discid isn't found on your system! Using fallback...")
			checkDataTrack()
			createFreedbString()
			puts _("freedb string = %s" % [@freedbString])
		end
		@discId = @freedbString.split()[0]
	end

	def checkDataTrack
		startSector = nil
		lastSector = nil
		if @query.include?('track_num = 176') # 176 = 0xb0 = end of data track??? # only MacOS version prints this
			@query.split('/n').each do |line|
				startSector = line.split()[5].to_i if (line[0,9] == "track_num" && startSector == nil)
				lastSector = line.split()[5].to_i if line[0,15] == 'track_num = 176'
			end
		elsif installed('cd-info') #from the libcdio library
			@query = `cd-info -C #{@cdrom}`
			if @query.include?(' data ')
				@query.split('/n').each do |line|
					startSector = line.split()[2].to_i if (line =~ /\s+data\s+/ && startSector == nil)
					lastSector = line.split()[2].to_i if line =~ /leadout/
				end
			end
		end

		if startSector != nil && lastSector != nil
			puts "Data track is detected!"
			@datatrack = [startSector, lastSector-startSector]
		end
	end

	def createFreedbString
		totalChecksum = 0
		seconds = 0
		freedbOffsets = ''
		totalSectors = 0
		audiotracks = @audiotracks
		startSector = @startSector
		lengthSector = @lengthSector

		#I've commented this out since it actually hurts the results here
		#if @datatrack
		#	audiotracks += 1 # take the datatrack in account
		#	startSector[audiotracks] = @datatrack[0] #add the start position of data track
		#	lengthSector[audiotracks] = @datatrack[1] #add the lenght of the data track
		#end

		(1..audiotracks).each do |track|
			checksum = 0
			seconds = (startSector[track] + 150) / 75 # MSF offset = 150
			seconds.to_s.split(/\s*/).each{|s| checksum += s.to_i} # for example cddb sum of 338 seconds = 3+3+8=14
			totalChecksum += checksum
		end

		totalSectors = (startSector[audiotracks] - startSector[1]) + lengthSector[audiotracks]
		seconds = totalSectors / 75

		discid =  ((totalChecksum % 0xff) << 24 | seconds << 8 | audiotracks).to_s(16)
		startSector.keys.sort.each{|track| freedbOffsets << (startSector[track] + 150).to_s + ' '}
		@freedbString = "#{discid} #{audiotracks} #{freedbOffsets}#{(totalSectors + 150) / 75}" # MSF offset = 150
	end

	# When a data track is the first track on a disc, cdparanoia is acting strange:
	# In the query it is showing as a start for 1s track the offset of the data track
	# When ripping this offset isn't used however !! To allow a correct rip of this disc
	# all startSectors have to be corrected. See also issue 196.
	
	# If there is no data track at the start, but we do have an offset this means some
	# hidden audio part. This part is marked as track 0. You can only assess this on
	# a cd-player by rewinding from 1st track on.

	def checkOffsetFirstTrack
		if @firstAudioTrack != 1 # a disc that starts with data
			dataOffset = @startSector[1]
			@startSector.each_key{|track| @startSector[track] = @startSector[track] - dataOffset}
		elsif @settings['ripHiddenAudio'] == false
			#do nothing extra when hidden audio shouldn't be ripped
			#in the cuesheet this part will be marked as a pregap (silence).
		elsif @startSector[1] != 0 && @startSector[1] / 75.0 > @settings['minLengthHiddenTrack']
			@startSector[0] = 0
			@lengthSector[0] = @startSector[1]
		elsif @startSector[1] != 0 # prepend the audio because it's not marked as a hidden track
			@lengthSector[1] = @lengthSector[1] + @startSector[1]
			@startSector[1] = 0
		end
	end

	def analyzeTOC
		checkOffsetFirstTrack()
		@lengthSector.each_value{|track| @totalSectors += track}
	end

	# return the startSector, example for track 1 getStartSector(1)
	def getStartSector(track)
		if track == "image"
			@startSector.key?(0) ? @startSector[0] : @startSector[1]
		else
			if @startSector.key?(track)
				return @startSector[track]
			else
				return false
			end
		end
	end

	# return the sectors of the track, example for track 1 getLengthSector(1)
	def getLengthSector(track)
		if track == "image"
			return @totalSectors
		else
			return @lengthSector[track]
		end
	end

	# return the length of the track in text, example for track 1 getLengthSector(1)
	def getLengthText(track)
		if track == "image"
			return @playtime
		else
			return @lengthText[track]
		end
	end

	# return the length in bytes of the track, example for track 1 getFileSize(1)
	def getFileSize(track)
		if track == "image"
			return 44 + @totalSectors * 2352
		else
			return 44 + @lengthSector[track] * 2352
		end
	end
end


# AdvancedToc is a class which helps detecting all special audio-cd
# features as hidden tracks, pregaps, etcetera. It does so by 
# analyzing the output of cdrdao's TOC output. The class is only
# opened when the user has the cuesheet enabled. This is so because
# there is not much of an advantage of detecting pregaps when
# they're just added to the file anyway. You want to detect
# the gaps so you can reproduce the original disc exactly. The
# cuesheet is necessary to store the gap info.

class AdvancedToc
attr_reader :log

	def initialize(settings)
		@settings = settings
		
		setVariables()
		readTOC()
	end
	
	# initialize all variables
	def setVariables
		@discType = "unknown"
		@dataTracks = Array.new
		@preEmphasis = Hash.new
		@pregap = Hash.new
		@silence = 0 #amount of sectors before the 1st track
		
		@artist = String.new
		@album = String.new
		@tracknames = Hash.new

		@index = 0
		@toc = Array.new
		@log = Array.new # saving the log messages

		require 'tmpdir'
	end

	# get an output location for the temporary Toc file
	def tocFile()
		return File.join(Dir.tmpdir, "temp_#{File.basename(@settings['cdrom'])}.toc") 
	end

	# fire the command to read the disc
	def readTOC()
		File.delete(tocFile()) if File.exist?(tocFile())  
		puts "Scanning disc with cdrdao" if @settings['debug']
		`cdrdao read-toc --device #{@settings['cdrom']} \"#{tocFile()}\" #{"2>&1" if !@settings['verbose']}`
		if $?.success?
			parseTOC()
		else
			"cdrdao is killed."
		end
	end

	# translate the file of cdrdao to a ruby array and interpret each line
	def parseTOC
		puts "Loading file: #{tocFile()}" if @settings['debug']
		@toc = File.read(tocFile()).split("\n")
		readDiscInfo()
		readTrackInfo()

		# give a message when no strange things are found
		if @preEmphasis.empty? && @pregap.empty? && @silence == 0
			@log << _("No pregaps, silences or pre-emphasis detected\n")
		end

		#set an extra whiteline before starting to rip
		@log << "\n"

		#might wanna fill the tags when otherwise Unknown is used
	end

	# parse the disc info
	def readDiscInfo
		@discType = @toc[0]
		puts "Disc type = #{@discType}" if @settings['debug']
		
		# continue reading the disc until the track info starts
		@index = 1
		while !@toc[@index].include?('//')
			if @toc[@index].include?('CD_TEXT')
				puts "Found cd_text for disc" if @settings['debug']
			elsif @toc[@index].include?('TITLE')
				@artist, @album = @toc[@index].strip().split(/\s\s+/)
				@artist = @artist[6..-1] #remove TITLE
				puts "Found artist for disc: #{@artist}" if @settings['debug']
				puts "Found album for disc: #{@album}" if @settings['debug']
			end
			@index += 1
		end
	end

	# parse the track info
	def readTrackInfo
		tracknumber = 0
		while @index != @toc.size
			if @toc[@index].include?('//')
				tracknumber += 1
				puts "Found info of tracknumber #{tracknumber}" if @settings['debug']
			elsif @toc[@index].include?('TRACK DATA')
				@dataTracks << tracknumber
				@log << _("Track %s is marked as a DATA track\n") % [tracknumber]
			elsif @toc[@index] == 'PRE_EMPHASIS'
				@preEmphasis[tracknumber] = true
				@log << _("Pre_emphasis detected on track %s\n") % [tracknumber]
			elsif @toc[@index].include?('START')
				sectorMinutes = 60 * 75 * @toc[@index][6..7].to_i
				sectorSeconds = 75 * @toc[@index][9..10].to_i
				@pregap[tracknumber] = sectorMinutes + sectorSeconds + @toc[@index][12..13].to_i
				@log << _("Pregap detected for track %s : %s sectors\n") % [tracknumber, @pregap[tracknumber]]
			elsif @toc[@index].include?('SILENCE')
				sectorMinutes = 60 * 75 * @toc[@index][9..10].to_i
				sectorSeconds = 75 * @toc[@index][11..12].to_i
				@silence = sectorMinutes + sectorSeconds + @toc[@index][14..15].to_i
				@log << _("Silence detected for track %s : %s sectors\n") % [tracknumber, @silence] 
			elsif @toc[@index].include?('TITLE')
				@toc[@index] =~ /".*"/ #ruby's  magical regular expressions
				@tracknames[tracknumber] = $&[1..-2] #don't need the quotes
				puts "CD-text found: Title = #{@tracknames[tracknumber]}" if @settings['debug']
			end
			@index += 1
		end
	end

	# return the pregap if found, otherwise return 0
	def getPregap(track)
		if @pregap.key?(track)
			return @pregap[track] 
		else
			return 0
		end
	end
	
	# return if a track has pre-emphasis
	def hasPreEmph(track)
		if @preEmphasis.key?(track)
			return true
		else
			return false
		end
	end
end

#The Cuesheet class is there to provide a Cuesheet. It is
#called from the Disc class after the toc scanning has
#finished. There are several variants for building a cuesheet.
#It at least needs a reference to all files. Single file is
#the most simple, since the prepend / append discussion isn't
#relevant here.
#
# NOTE Currently Data tracks are totally ignored for the cuesheet.
# INFO -> TRACK 01 = Start point of track hh:mm:ff (h =hours, m = minutes, f = frames
# INFO -> After each FILE entry should follow the format. Only WAVE and MP3 are allowed AND relevant.

class Cuesheet
	def initialize(settings, toc)
		@settings = settings
		@toc = toc
		@filetype = {'flac' => 'WAVE', 'wav' => 'WAVE', 'mp3' => 'MP3', 'vorbis' => 'WAVE', 'other' => 'WAVE'}
		allCodecs()
	end

	def allCodecs
		['flac','vorbis','mp3','wav','other'].each do |codec|
			if @settings[codec]
				@cuesheet = Array.new
				@codec = codec
				createCuesheet()
				saveCuesheet()
			end
		end
	end

	def time(sector) # minutes:seconds:leftover frames
		minutes = sector / 4500 # 75 frames/second * 60 seconds/minute
		seconds = (sector % 4500) / 75
		frames = sector % 75 # leftover
		return "#{sprintf("%02d", minutes)}:#{sprintf("%02d", seconds)}:#{sprintf("%02d", frames)}"
	end

	def createCuesheet
		@cuesheet << "REM GENRE #{@settings['Out'].genre}"
		@cuesheet << "REM DATE #{@settings['Out'].year}"
		@cuesheet << "REM COMMENT \"Rubyripper #{$rr_version}\""
		@cuesheet << "REM DISCID #{@settings['cd'].discId}"
		@cuesheet << "REM FREEDB_QUERY \"#{@settings['cd'].freedbString.chomp}\""
		@cuesheet << "PERFORMER \"#{@settings['Out'].artist}\""
		@cuesheet << "TITLE \"#{@settings['Out'].album}\""

		# image rips should handle all info of the tracks at once
		@settings['tracksToRip'].each do |track|
			if track == "image"
				writeFileLine(track)
				(1..@settings['cd'].audiotracks).each{|audiotrack| trackinfo(audiotrack)}
			else
				if @toc.hasPreEmph(track) && (@settings['preEmphasis'] == 'cue' || !installed('sox'))
					@cuesheet << "FLAGS PRE"
					puts "Added PRE(emphasis) flag for track #{track}." if @settings['debug']
				end
				
				# do not put Track 00 AUDIO, but instead only mention the filename
				if track == 0
					writeFileLine(track)
				# when a hidden track exists first enter the trackinfo, then the file
				elsif track == 1 && @settings['cd'].getStartSector(0)
					trackinfo(track)
					writeFileLine(track)
					# if there's a hidden track, start the first track at 0
					@cuesheet << "    INDEX 01 #{time(0)}"
				# when no hidden track exists write the file and then the trackinfo
				elsif track == 1 && !@settings['cd'].getStartSector(0)
					writeFileLine(track)
					trackinfo(track)
				elsif @settings['pregaps'] == "prepend" || @toc.getPregap(track) == 0
					writeFileLine(track)
					trackinfo(track)
				else
					trackinfo(track)	
				end
			end
		end
	end

	#writes the location of the file in the Cue
	def writeFileLine(track)
		@cuesheet << "FILE \"#{File.basename(@settings['Out'].getFile(track, @codec))}\" #{@filetype[@codec]}"
	end
	
	# write the info for a single track
	def trackinfo(track)
		@cuesheet << "  TRACK #{sprintf("%02d", track)} AUDIO"
		
		if track == 1 && @settings['ripHiddenAudio'] == false && @settings['cd'].getStartSector(1) > 0
			@cuesheet << "  PREGAP #{time(@settings['cd'].getStartSector(1))}"
		end

		@cuesheet << "    TITLE \"#{@settings['Out'].getTrackname(track)}\""
		if @settings['Out'].getVarArtist(track) == ''
			@cuesheet << "    PERFORMER \"#{@settings['Out'].artist}\""
		else
			@cuesheet << "    PERFORMER \"#{@settings['Out'].getVarArtist(track)}\""
		end
		
		trackindex(track)
	end
	
	def trackindex(track)
		if @settings['image']
			# There is a different handling for track 1 and the rest
			if track == 1 && @settings['cd'].getStartSector(1) > 0
				@cuesheet << "    INDEX 00 #{time(0)}"
				@cuesheet << "    INDEX 01 #{time(@settings['cd'].getStartSector(track))}"
			elsif @toc.getPregap(track) > 0 
				@cuesheet << "    INDEX 00 #{time(@settings['cd'].getStartSector(track))}"
				@cuesheet << "    INDEX 01 #{time(@settings['cd'].getStartSector(track) + @toc.getPregap(track))}"
			else # no pregap
				@cuesheet << "    INDEX 01 #{time(@settings['cd'].getStartSector(track))}"
			end
		elsif @settings['pregaps'] == "append" && @toc.getPregap(track) > 0 && track != 1
			@cuesheet << "    INDEX 00 #{time(@settings['cd'].getLengthSector(track-1) - @toc.getPregap(track))}"
			writeFileLine(track)
			@cuesheet << "    INDEX 01 #{time(0)}"
		else
			# There is a different handling for track 1 and the rest
			# If no hidden audio track or modus is prepending
			if track == 1 && @settings['cd'].getStartSector(1) > 0 && !@settings['cd'].getStartSector(0)
				@cuesheet << "    INDEX 00 #{time(0)}"
				@cuesheet << "    INDEX 01 #{time(@toc.getPregap(track))}"
			elsif track == 1 && @settings['cd'].getStartSector(0)
				@cuesheet << "    INDEX 01 #{time(0)}"
			elsif @settings['pregaps'] == "prepend" && @toc.getPregap(track) > 0 
				@cuesheet << "    INDEX 00 #{time(0)}"
				@cuesheet << "    INDEX 01 #{time(@toc.getPregap(track))}"
			elsif track == 0 # hidden track needs index 00
				@cuesheet << "    INDEX 00 #{time(0)}"
			else # no pregap or appended to previous which means it starts at 0
				@cuesheet << "    INDEX 01 #{time(0)}"
			end
		end
	end

	def saveCuesheet
		file = File.new(@settings['Out'].getCueFile(@codec), 'w')
		@cuesheet.each do |line|
			file.puts(line)
		end
		file.close()
	end
end

class Metadata
attr_reader :status
attr_accessor :artist, :album, :genre, :year, :tracklist, :varArtists, :discNumber
	
	def initialize(disc, settings)
		@disc = disc
		@gui = settings['instance']
		@verbose = settings['verbose']
		@settings = settings
		setVariables()
	end

	def setVariables
		@artist = _('Unknown')
		@album = _('Unknown')
		@genre = _('Unknown')
		@year = '0'
		@discNumber = false
		@tracklist = Array.new
		@disc.audiotracks.times{|number| @tracklist << _("Track %s") % [number + 1]}
		@rawResponse = Array.new
		@choices = Array.new
		@varArtists = Array.new
		@varArtistsBackup = Array.new
		@backupTracklist = Array.new
		@status = false
	end

	def freedb(freedbSettings, alwaysFirstChoice=true)
		@freedbSettings = freedbSettings
		@alwaysFirstChoice = alwaysFirstChoice

		if not @disc.freedbString.empty? #no disc found
			searchMetadata()
		else
			@status = ["noAudioDisc", _("No audio disc found in %s") % [@cdrom]]
 		end
	end

	def searchMetadata
 		if File.exist?(@settings['freedbCache'])
			@metadataFile = YAML.load(File.open(@settings['freedbCache']))
			#in case it got corrupted somehow
			@metadataFile = Hash.new if @metadataFile.class != Hash
		else
			@metadataFile = Hash.new
		end

		if @disc.freedbString != @disc.oldFreedbString # Scanning the same disc will always result in an new freedb fetch.
			if @metadataFile.has_key?(@disc.freedbString) || findLocalMetadata #is the Metadata somewhere local?
				if @metadataFile.has_key?(@disc.freedbString)
					@rawResponse = @metadataFile[@disc.freedbString]
				end
				@tracklist.clear()
				handleResponse()
				@status = true # Give the signal that we're finished
				return true
			end
		end

		if @verbose ; puts "preparing to contact freedb server" end
		handshake()
	end

	def findLocalMetadata
		if File.directory?(dir = File.join(ENV['HOME'], '.cddb'))
			Dir.foreach(dir) do |subdir|
				if subdir == '.' || subdir == '..' || !File.directory?(File.join(dir, subdir)) ;  next end
				Dir.foreach(File.join(dir, subdir)) do |file|
					if file == @disc.freedbString[0,8]
						puts "Local file found #{File.join(dir, subdir, file)}"
						# convert the string to an array, since ruby-1.9 handles these differently
						@rawResponse = File.read(File.join(dir, subdir, file)).split("\n")
						return true
					end
				end
			end
		end
		return false
	end
	
	def handshake
		require 'net/http' #automatically loads the 'uri' library
		require 'cgi' #for communicating with the server
		
		@url = URI.parse(@freedbSettings['site'])
		
		if ENV['http_proxy']
			@proxy = URI.parse(ENV['http_proxy'])
			@server = Net::HTTP.new(@url.host, @url.port, @proxy.host,
				@proxy.port, @proxy.user,
				@proxy.password ? CGI.unescape(@proxy.password) : '')
		else
			@server = Net::HTTP.new(@url.host, @url.port)
		end
		
		@query = @url.path + "?cmd=cddb+query+" + CGI.escape("#{@disc.freedbString.chomp}") + "&hello=" + 
			CGI.escape("#{@freedbSettings['username']} #{@freedbSettings['hostname']} rubyripper #{$rr_version}") + "&proto=6"
		if @verbose ; puts "Created query string: #{@query}" end

		begin
			respons, @answer = @server.get(@query)
			requestDisc()
		rescue
			puts "Exception thrown: #{$!}"
			@status = ["networkDown", _("Couldn't connect to freedb server. Network down?\n\nDefault values will be shown...")]
		end
	end	

	def requestDisc # ask for matches on cd, if there are multiple, interaction with user is possible
		if @answer[0..2] == '200'  #There was only one hit found
			if @verbose ; puts "One hit found; parsing" end
			temp, @category, @discid = @answer.split()
			freedbChoice()
		elsif @answer[0..2] == '211' || @answer[0..2] == '210' #Multiple hits were found
			multipleHits()
			@choices.each{|choice| puts "choice #{choice}"}
			if (@alwaysFirstChoice || @choices.length < 3) ; freedbChoice(0) #Always choose the first one
			else @status = ["choices", @choices] #Let the user choose
			end
		elsif @answer[0..2] == '202'
			@status = ["noMatches", _("No match in Freedb database. Default values are used.")]
		else
			@status = ["unknownReturnCode", _("cddb_query return code = %s. Return code not supported.") % [@answer[0..2]]]
		end
	end
	
	def multipleHits
		discNames = @answer.split("\n")[1..@answer.length]; # remove the first line, which we know is the header
		discNames.each { |disc| @choices << disc.strip() unless (disc.strip() == "." || disc.strip().length == 0) }
		@choices << _("Keep defaults / don't use freedb") #also use the option to keep defaults
	end

	def freedbChoice(choice=false)
		if choice != false
			if choice == @choices.size - 1 # keep defaults?
				@status = true
				return true
			end
			@category, @discid = @choices[choice].split
		end
		rawResponse()
		@tracklist.clear() #Now fill it with the real tracknames
		handleResponse()
		@status = true
	end

	def rawResponse #Retrieve all usefull metadata into @rawResponse
		@query = @url.path + "?cmd=cddb+read+" + CGI.escape("#{@category} #{@discid}") + "&hello=" + 
			CGI.escape("#{@freedbSettings['username']} #{@freedbSettings['hostname']} rubyripper #{$rr_version}") + "&proto=6"
		if @verbose ; puts "Created fetch string: #{@query}" end
		
		response, answer = @server.get(@query)
		answers = answer.split("\n")
		answers.each do |line|
			line.chomp!
			@rawResponse << line unless (line == nil || line[-1,1] == '=' ||line[0,1] == '#' || line[0,1] == '.' )
		end
		saveResponse()
	end
	
	def saveResponse
		if File.exist?(@settings['freedbCache'])
			@metadataFile = YAML.load(File.open(@settings['freedbCache']))
		else
			@metadataFile = Hash.new
		end

		@metadataFile[@disc.freedbString] = @rawResponse
		
		file = File.new(@settings['freedbCache'], 'w')
		file.write(@metadataFile.to_yaml)
		file.close()
	end
	
	def saveChanges
		@rawResponse = Array.new
		@rawResponse << "DTITLE=#{@artist} \/ #{@album}"
		@rawResponse << "DYEAR=#{@year}"
		@rawResponse << "DGENRE=#{@genre}"
		
		@disc.audiotracks.times do |index|
			if @varArtists.empty?
				@rawResponse << "TTITLE#{index}=#{@tracklist[index]}"
			else
				@rawResponse << "TTITLE#{index}=#{@varArtists[index]} / #{@tracklist[index]}"
			end
		end
		saveResponse()
		return true
	end
	
	def handleResponse #Make some usefull variables from the raw_response.
		@rawResponse.each do |line|
			line.strip! #remove any newline characters
			if line =~ /DTITLE=/
				if @artist == _('Unknown') #first time we look at a DTITLE field (can have two lines at maximum)
					(@artist, @album) = $'.split(/\s+\/\s+/) # Remove the '/' with spaces around it, example DTITLE= Judas Priest     /     Sin After Sin
					if @artist == nil; @artist = _('Unknown') end
					if @album == nil; @album = _('Unknown') end
				elsif $' != nil # 2nd line with DTITLE, assume the second line is the continuation of the album name
					@album = "#{@album}#{$'}"
				end
			elsif line =~ /DYEAR=/
				@year = $' ; if @year == nil ; @year = 0 end
			elsif line =~ /DGENRE=/
				@genre = $' ; if @genre == nil ; @genre = _('Unknown') end
			elsif line =~ /TTITLE\d*=/
				trackname = $' # may also include variable artist
				line =~ /\d+/ ; tracknumber = $&.to_i #ruby magic, $& == the just matched regular expression
				if trackname != nil && @tracklist.empty? #1st track
					@tracklist << trackname
				elsif trackname != nil && @tracklist.length == tracknumber #counting of tracknumber starts with 0
					@tracklist << trackname 
				elsif trackname != nil #already had a line for this track, so add this trackname to the previous one
					@tracklist[-1] += trackname
				end
			end
		end
		checkVarArtist()
	end

#Various artist albums have different ways to show the artist and trackname
#Most common notation is ARTIST / TITLE
#Next to that is ARTIST - TITLE
#Then we got "TITLE" by ARTIST
# Some albums use a mixture of these schemes

	def checkVarArtist
		sep = ''
		varArtist = false
		@disc.audiotracks.times do |tracknumber|
			if @tracklist[tracknumber] && @tracklist[tracknumber] =~ /[-\/]|\sby\s/
				varArtist = true
			else
				varArtist = false 	# one of the tracks does not conform to VA schema
				break  					# consider the whole album as not VA
			end

		end

		if varArtist == true
			@backupTracklist = @tracklist.dup() #backup before overwrite with new values
			@tracklist.each_index{|index| @varArtists[index], @tracklist[index] = @tracklist[index].split(/\s*[-\/]|(\sby\s)\s*/)} #remove any spaces (\s) around sep
		end
	end
	
	def undoVarArtist
		# first backup in case we want to revert back
		@varArtistsBackup = @varArtists.dup()
		@varTracklistBackup = @tracklist.dup()

		# reset original values
		@varArtists = Array.new

		# restore the tracklist
		@tracklist = @backupTracklist.dup
	end

#reset to various artists when originally detected as such and made undone
	def redoVarArtist
		if !@backupTracklist.empty? && !@varArtistsBackup.empty?
			@tracklist = @varTracklistBackup
			@varArtists = @varArtistsBackup
		end
	end
end

# Output is a helpclass that defines all the names of the directories, 
# filenames and tags. It filters out special characters that are not
# well supported in the different platforms. It also offers some help
# functions to create the output dirs and to get a preview of the output.
# Since all the info is here, also create the playlist files. The cuesheets
# are also made with help of the Cuesheet class.
# Output is initialized as soon as the player pushes Rip Now!

class Output
attr_reader :status, :artist, :album, :year, :genre
	
	def initialize(settings)
		@settings = settings
		@md = @settings['cd'].md
		@codecs = ['flac', 'vorbis', 'mp3', 'wav', 'other']
		# Status of the class is false until proven otherwise
		@status = false

		# the output of the dirs for each codec, and files for each tracknumber + codec.
		@dir = Hash.new
		@file = Hash.new
		@image = Hash.new

		# the metadata made ready for tagging usage
		@artist = String.new
		@album = String.new
		@year = String.new
		@genre = String.new
		@tracklist = Hash.new
		@varArtists = Hash.new
		@otherExtension = String.new
		
		splitDirFile()
		checkNames()
		setDirectory()
		attemptDirCreation()
	end

	# split the filescheme into a dir and a file
	def splitDirFile
		if @settings['image']
			fileScheme = @settings['naming_image']
		elsif @md.varArtists.empty?
			fileScheme =  @settings['naming_normal']
		else
			fileScheme = @settings['naming_various']
		end
		
		# the basedir is added later on, since we don't want to change it
		@dirName, @fileName = File.split(fileScheme)
	end

# Do a few sanity checks
# 1) Remove dot(s) from the albumname when it's the start of a directory,
# otherwise they're hidden files in linux.
# 2) Check if %va exists in filescheme for normal artists
# 3) Check if %n exists in single file rip scheme
# 4) Check if %va exists in single file rip scheme
# 5) Check if %t exists in single file rip scheme

	def checkNames
		if @dirName.include?("/%b") && @md.album[0,1] == '.' 
 			@dirName.sub!(/\.*/, '')
 		end

		if @md.varArtists.empty? && @fileName.include?('%va')
			@fileName.gsub!('%va', '')
			puts "Warning: '%va' in the filescheme for normal cd's makes no sense!"
			puts "This is automatically removed"
		end

		if @settings['image']
			if @fileName.include?('%n')
				@fileName.gsub!('%n', '')
				puts "Warning: '%n' in the filescheme for image rips makes no sense!"
				puts "This is automatically removed"
			end
			
			if @fileName.include?('%va')
				@fileName.gsub!('%va', '')
				puts "Warning: '%va' in the filescheme for image rips makes no sense!"
				puts "This is automatically removed"
			end

			if @fileName.include?('%t')
				@fileName.gsub!('%t', '')
				puts "Warning: '%t' in the filescheme for image rips makes no sense!"
				puts "This is automatically removed"
			end
		end
	end

	# fill the @dir variable with all output dirs
	def setDirectory
		@codecs.each do |codec|
			if @settings[codec]
				@dir[codec] = giveDir(codec)
			end
		end
	end

	# determine the output dir
	def giveDir(codec)
		dirName = @dirName.dup

		# no forward slashes allowed in dir names
		@artistFile = @md.artist.gsub('/', '')
		@albumFile = @md.album.gsub('/', '')

		# do not allow multiple directories for various artists
		{'%a' => @artistFile, '%b' => @albumFile, '%f' => codec, '%g' => @md.genre,
		'%y' => @md.year, '%va' => @artistFile}.each do |key, value|
			dirName.gsub!(key, value)
		end

		if @md.discNumber != false
			dirName = File.join(dirName, "CD #{sprintf("%02d", @md.discNumber)}")
		end
		
		dirName = fileFilter(dirName, true)
		return File.expand_path(File.join(@settings['basedir'], dirName))
	end

	# (re)attempt creation of the dirs, when succesfull create the filenames
	def attemptDirCreation
		if not checkDirRights ; return false end
		if not checkDirExistence() ; return false end
		createDir()
		createTempDir()
		setMetadata()
		findExtensionOther()
		setFileNames()
		createFiles()
		@status = true
	end
	
	def findExtensionOther
		if @settings['other']
			@settings['othersettings'] =~ /"%o".\S+/ # ruby magic, match %o.+ any characters that are not like spaces
			@otherExtension = $&[4..-1]
			@settings['othersettings'].gsub!(@otherExtension, '') # remove any references to the ext in the settings
		end
	end

	# create playlist + cuesheet files
	def createFiles
		['flac','vorbis','mp3','wav','other'].each do |codec|
			if @settings[codec] && @settings['playlist'] && !@settings['image']
				createPlaylist(codec)
			end
		end
	end

	# check write access of the output dirs
	def checkDirRights
		@dir.values.each do |directory|
			dir = directory
			# search for the first existing directory
			while not File.directory?(dir) ; dir = File.dirname(dir) end
			
			if not File.writable?(dir)
				@status = ["error", _("Can't create output directory!\nYou have no writing acces in dir %s") % [dir]]
 				return false
 			end
		end
		return true
	end

	# check the existence of the output dir
	def checkDirExistence
		@dir.values.each do |dir|
			puts dir if @settings['debug']
			if File.directory?(dir)
				@status = ["dir_exists", dir]
				return false			
			end
		end
		return true
	end

	# create the output dirs
	def createDir
		@dir.values.each{|dir| FileUtils.mkdir_p(dir)}
	end

	# create the temp dir
	def createTempDir
		if not File.directory?(getTempDir)
			FileUtils.mkdir_p(getTempDir)
		end
	end

	# fill the @file variable, so we have for example @file['flac'][1]
	def setFileNames
		@codecs.each do |codec|
			if @settings[codec]
				@file[codec] = Hash.new
				if @settings['image']
					@image[codec] = giveFileName(codec)
				else
					@settings['cd'].audiotracks.times do |track|
						@file[codec][track + 1] = giveFileName(codec, track)
					end
				end
			end
		end

		#if no hidden track is detected, getStartSector will return false
		if @settings['cd'].getStartSector(0)
			setHiddenTrack()
		end
	end

	# give the filename for given codec and track
	def giveFileName(codec, track=0)
		file = @fileName.dup
		
		# the artist should always refer to the artist that is valid for the track
		if getVarArtist(track + 1) == '' ; artist = @md.artist ; varArtist = ''
		else artist = getVarArtist(track + 1) ; varArtist = @md.artist end
		
		{'%a' => artist, '%b' => @md.album, '%f' => codec, '%g' => @md.genre,
		'%y' => @md.year, '%n' => sprintf("%02d", track + 1), '%va' => varArtist, 
		'%t' => getTrackname(track + 1)}.each do |key, value|
			file.gsub!(key, value)
		end

		# other codec has the extension already in the command
		if codec == 'flac' ; file += '.flac'
		elsif codec == 'vorbis' ; file += '.ogg'
		elsif codec == 'mp3' ; file += '.mp3'
		elsif codec == 'wav' ; file += '.wav'
		elsif codec == 'other' ; file += @otherExtension
		end
		
		filename = fileFilter(file)
		puts filename if @settings['debug']
		return filename
	end

	# Fill the metadata, made ready for tagging
	def setMetadata
		@artist = tagFilter(@md.artist)
		@album = tagFilter(@md.album)
		@genre = tagFilter(@md.genre)
		@year = tagFilter(@md.year)
		@settings['cd'].audiotracks.times do |track|
			@tracklist[track+1] = tagFilter(@md.tracklist[track])
		end
		if not @md.varArtists.empty?
			@settings['cd'].audiotracks.times do |track|
				@varArtists[track+1] = tagFilter(@md.varArtists[track])
			end
		end
	end

	# Fill the metadata for the hidden track
	def setHiddenTrack
		@tracklist[0] = tagFilter(_("Hidden Track").dup)
		@varArtists[0] = tagFilter(_("Unknown Artist").dup) if not @md.varArtists.empty?
		@codecs.each{|codec| @file[codec][0] = giveFileName(codec, -1) if @settings[codec]}
	end

	# characters that will be changed for filenames (monkeyproof for FAT32)
	def fileFilter(var, isDir=false)
		if not isDir
			var.gsub!('/', '') #no slashes allowed in filenames
		end
		var.gsub!(':', '') #no colons allowed in FAT
		var.gsub!('*', '') #no asterix allowed in FAT
		var.gsub!('?', '') #no question mark allowed in FAT
		var.gsub!('<', '') #no smaller than allowed in FAT
		var.gsub!('>', '') #no greater than allowed in FAT
		var.gsub!('|', '') #no pipe allowed in FAT
		var.gsub!('\\', '') #the \\ means a normal \
 		var.gsub!('"', '')
 		
		allFilter(var)

		if @settings['noSpaces'] ; var.gsub!(" ", "_") end
 		if @settings['noCapitals'] ; var.downcase! end
		return var.strip
	end

	#characters that will be changed for tags
	def tagFilter(var)
		allFilter(var)

		#Add a slash before the double quote chars, 
		#otherwise the shell will complain
		var.gsub!('"', '\"')
		return var.strip
	end

	# characters that will be changed for tags and filenames
	def allFilter(var)
		var.gsub!('`', "'")
		
		# replace any underscores with spaces, some freedb info got 
		# underscores instead of spaces
		if not @settings['noSpaces'] ; var.gsub!('_', ' ') end

		if var.respond_to?(:encoding)
			# prepare for byte substitutions
			enc = var.encoding
			var.force_encoding("ASCII-8BIT")
		end

		# replace utf-8 single quotes with latin single quote 
		var.gsub!(/\342\200\230|\342\200\231/, "'") 
		
		# replace utf-8 double quotes with latin double quote
		var.gsub!(/\342\200\234|\342\200\235/, '"') 

		if var.respond_to?(:encoding)
			# restore the old encoding
			var.force_encoding(enc)
		end
	end

	# add the first free number as a postfix to the output dir
 	def postfixDir
 		postfix = 1
 		@dir.values.each do |dir|
			while File.directory?(dir + "\##{postfix}")
				postfix += 1
			end
		end
		@dir.keys.each{|key| @dir[key] = @dir[key] += "\##{postfix}"}
		attemptDirCreation()
 	end
 	
	# remove the existing dir, starting with the files in it
 	def overwriteDir
 		@dir.values.each{|dir| cleanDir(dir) if File.directory?(dir)}
		attemptDirCreation()
 	end

    # clean a directory, starting with the files in it
	def cleanDir(dir)
		Dir.foreach(dir) do |file|
			if File.directory?(file) && file[0..0] != '.' ; cleanDir(File.join(dir, file)) end
			filename = File.join(dir, file)
			File.delete(filename) if File.file?(filename)
		end
		Dir.delete(dir)
	end

	# create Playlist for each codec
	def createPlaylist(codec)
		playlist = File.new(File.join(@dir[codec], 
			"#{@artistFile} - #{@albumFile} (#{codec}).m3u"), 'w')
		
		@settings['tracksToRip'].each do |track|
			playlist.puts @file[codec][track]
		end

		playlist.close
	end

	# clean temporary Dir (when finished)
	def cleanTempDir
		cleanDir(getTempDir()) if File.directory?(getTempDir())
	end

	# return the first directory (for the summary)
	def getDir
		return @dir.values[0]
	end

	# return the full filename of the track (starting with 1) or image
	def getFile(track, codec)
		if track == "image"
			return File.join(@dir[codec], @image[codec])		
		else
			return File.join(@dir[codec], @file[codec][track])
		end	
	end

	# return the toc file of AdvancedToc class
	def getTocFile
		return File.join(getTempDir(), "#{@artistFile} - #{@albumFile}.toc")
	end

	# return the full filename of the log
	def getLogFile(codec)
		return File.join(@dir[codec], 'ripping.log')
	end

	# return the full filename of the cuesheet
	def getCueFile(codec)
		return File.join(@dir[codec], "#{@artistFile} - #{@albumFile} (#{codec}).cue")
	end

	def getTempFile(track, trial)
		if track == "image"
			return File.join(getTempDir(), "image_#{trial}.wav")
		else
			return File.join(getTempDir(), "track#{track}_#{trial}.wav")
		end
	end

	#return the temporary dir
	def getTempDir
		return File.join(File.dirname(@dir.values[0]), "temp_#{File.basename(@settings['cd'].cdrom)}/")
	end

	#return the trackname for the metadata
	def getTrackname(track)
		if @tracklist[track] == nil
			return ''
		else
			return @tracklist[track]
		end
	end

	#return the artist for the metadata
	def getVarArtist(track)
		if @varArtists[track] == nil
			return ''
		else
			return @varArtists[track]
		end
	end
end

class SecureRip
	attr_writer :cancelled 
	
	def initialize(settings, encoding)
		@settings = settings
		@encoding = encoding
		@cancelled = false
		@reqMatchesAll = @settings['req_matches_all'] # Matches needed for all chunks
		@reqMatchesErrors = @settings['req_matches_errors'] # Matches needed for chunks that didn't match immediately
		@progress = 0.0 #for the progressbar
		@sizeExpected = 0
		@timeStarted = Time.now # needed for a time break after 30 minutes
		ripTracks()
	end

	def ripTracks
		@settings['log'].ripPerc(0.0, "ripper") # Give a hint to the gui that ripping has started
		
		@settings['tracksToRip'].each do |track|
			break if @cancelled == true
			puts "Ripping track #{track}" if @settings['debug'] && track != 'image'
			puts "Ripping image" if @settings['debug'] && track == 'image'
			ripTrack(track)
		end
		
		eject(@settings['cd'].cdrom) if @settings['eject'] 
	end

	
	# Due to a bug in cdparanoia the -Z setting has to be replaced for last track.
	# This is only needed when an offset is set. See issue nr. 13.
	def checkParanoiaSettings(track)
		if @settings['rippersettings'].include?('-Z') && @settings['offset'] != 0
			if track == "image" || track == @settings['cd'].audiotracks
				@settings['rippersettings'].gsub!(/-Z\s?/, '')
			end
		end
	end

	# rip one output file
	def ripTrack(track)
		checkParanoiaSettings(track)

		#reset next three variables for each track
		@errors = Hash.new()
		@filesizes = Array.new
		@trial = 0

		# first check if there's enough size available in the output dir
		if sizeTest(track)
			if main(track)
				deEmphasize(track)
				@encoding.addTrack(track)
			else 
				return false
			end #ready to encode
		end
	end
	
	# check if the track needs to be corrected
	# the de-emphasized file needs another name
	# when sox is finished move it back to the original name
	def deEmphasize(track)
		if @settings['create_cue'] && @settings['preEmphasis'] == "sox" &&
			@settings['cd'].toc.hasPreEmph(track) && installed(sox)
			`sox #{@settings['Out'].getTempFile(track, 1)} #{@settings['Out'].getTempFile(track, 2)}`
			if $?.success?
				FileUtils.mv(@settings['Out'].getTempFile(track, 2), @settings['Out'].getTempFile(track, 1))
			else
				puts "sox failed somehow."
			end
		end
	end

	def sizeTest(track)
		puts "Expected filesize for #{if track == "image" ; track else "track #{track}" end}\
		is #{@settings['cd'].getFileSize(track)} bytes." if @settings['debug'] 

		if installed('df')				
			freeDiskSpace = `LANG=C df \"#{@settings['Out'].getDir()}\"`.split()[10].to_i
			puts "Free disk space is #{freeDiskSpace} MB" if @settings['debug']
			if @settings['cd'].getFileSize(track) > freeDiskSpace*1000
				@settings['log'].add(_("Not enough disk space left! Rip aborted"))
				return false
			end
		end
		return true
	end
	
	def main(track)
		@reqMatchesAll.times{if not doNewTrial(track) ; return false end} # The amount of matches all sectors should match
		analyzeFiles(track) #If there are differences, save them in the @errors hash
				
		while @errors.size > 0
			if @trial > @settings['max_tries'] && @settings['max_tries'] != 0 # We would like to respect our users settings, wouldn't we?
				@settings['log'].add(_("Maximum tries reached. %s chunk(s) didn't match the required %s times\n") % [@errors.length, @reqMatchesErrors])
				@settings['log'].add(_("Will continue with the file we've got so far\n"))
				@settings['log'].mismatch(track, 0, @errors.keys, @settings['cd'].getFileSize(track), @settings['cd'].getLengthSector(track)) # zero means it is never solved.
				break # break out loop and continue using trial1
			end
			
			doNewTrial(track)
			break if @cancelled == true

			if @trial > @reqMatchesErrors # If the reqMatches errors is equal of higher to @trial, no match would ever be found, so skip
				correctErrorPos(track)
			else
				readErrorPos(track)
			end 
		end
		
		getDigest(track) # Get a MD5-digest for the logfile
		@progress += @settings['percentages'][track]
		@settings['log'].ripPerc(@progress)
		return true
	end
	
	def doNewTrial(track)
		fileOk = false
	
		while (!@cancelled && !fileOk)
			@trial += 1
			rip(track)
			if fileCreated(track) && testFileSize(track)
				fileOk = true
			end
		end

		# when cancelled fileOk will still be false
		return fileOk
	end
	
	def fileCreated(track) #check if cdparanoia outputs wav files (passing bad parameters?)
		if not File.exist?(@settings['Out'].getTempFile(track, @trial))
			@settings['instance'].update("error", _("Cdparanoia doesn't output wav files.\nCheck your settings please."))
			return false
		end
		return true
	end
	
	def testFileSize(track) #check if wavfile is of correct size
		sizeDiff = @settings['cd'].getFileSize(track) - File.size(@settings['Out'].getTempFile(track, @trial))

		# at the end the disc may differ 1 sector on some drives (2352 bytes)
		if sizeDiff == 0
			# expected size matches exactly
		elsif sizeDiff < 0
			puts "More sectors ripped than expected: #{sizeDiff / 2352} sector(s)" if @settings['debug']
		elsif @settings['offset'] > 0 && (track == "image" || track == @settings['cd'].audiotracks)
			@settings['log'].add(_("The ripped file misses %s sectors.\n") % [sizeDiff / 2352.0])			
			@settings['log'].add(_("This is known behaviour for some drives when using an offset.\n"))		
			@settings['log'].add(_("Notice that each sector is 1/75 second.\n"))
		elsif @cancelled == false
			if @settings['debug']
				puts "Some sectors are missing for track #{track} : #{sizeDiff} sector(s)"
				puts "Filesize should be : #{@settings['cd'].getFileSize(track)}"
			end

			#someone might get out of free diskspace meanwhile
			@cancelled = true if not sizeTest(track)
			
			File.delete(@settings['Out'].getTempFile(track, @trial)) # Delete file with wrong filesize
			@trial -= 1 # reset the counter because the filesize is not right
			@settings['log'].add(_("Filesize is not correct! Trying another time\n"))
			return false
		end
		return true
	end

	def analyzeFiles(track)
		@settings['log'].add(_("Analyzing files for mismatching chunks\n"))
		files = Array.new
		@reqMatchesAll.times do |time|
			files << File.new(@settings['Out'].getTempFile(track, time + 1), 'r')
		end
				
		(@reqMatchesAll - 1).times do |time|
			index = 0 ; files.each{|file| file.pos = 44} # 44 = wav container overhead, 2352 = size for a audiocd sector as used in cdparanoia
			while index + 44 < @settings['cd'].getFileSize(track)
				if !@errors.key?(index) && files[0].read(2352) != files[time + 1].read(2352) # Does this sector matches the previous ones? and isn't the position already known?
					files.each{|file| file.pos = index + 44} # Reset each read position of the files
					@errors[index] = Array.new
					files.each{|file| @errors[index] << file.read(2352)} # Save the chunk for all files in the just created array
				end
				index += 2352
			end
		end
		
		files.each{|file| file.close}
		
		# Remove the files now we analyzed them. Differences are saved in memory.
		(@reqMatchesAll - 1).times{|time| File.delete(@settings['Out'].getTempFile(track, time + 2))}
 
		if @errors.size == 0
			@settings['log'].add(_("Every chunk matched %s times :)\n") % [@reqMatchesAll])
		else
			@settings['log'].mismatch(track, @trial, @errors.keys, @settings['cd'].getFileSize(track), @settings['cd'].getLengthSector(track)) # report for later position analysis
			@settings['log'].add(_("%s chunk(s) didn't match %s times.\n") % [@errors.length, @reqMatchesAll])
		end
	end
	
	# When required matches for mismatched sectors are bigger than there are 
	# trials to be tested, readErrorPos() just reads the mismatched sectors
	# without analysing them.
	# Wav-containter overhead = 44 bytes.
	# Audio-cd sector = 2352 bytes.

	def readErrorPos(track)
		file = File.new(@settings['Out'].getTempFile(track, @trial), 'r')
		@errors.keys.sort.each do |start_chunk|
			file.pos = start_chunk + 44
			@errors[start_chunk] << file.read(2352)
		end
		file.close

		# Remove the file now we read it. Differences are saved in memory.
		File.delete(@settings['Out'].getTempFile(track, @trial))

		# Give an update for the trials for later analysis
		@settings['log'].mismatch(track, @trial, @errors.keys, @settings['cd'].getFileSize(track), @settings['cd'].getLengthSector(track)) 
	end
	
	# Let the errors 'wave' out. For each sector that isn't unique across
	# different trials, try to find at least @reqMatchesErrors matches. If
	# indeed this amount of matches is found, correct the sector in the
	# reference file (trial 1).

	def correctErrorPos(track)
		file1 = File.new(@settings['Out'].getTempFile(track, 1), 'r+')
		file2 = File.new(@settings['Out'].getTempFile(track, @trial), 'r')
		
		# Sort the hash keys to prevent jumping forward and backwards in the file
		@errors.keys.sort.each do |start_chunk|
			file2.pos = start_chunk + 44
			@errors[start_chunk] << temp = file2.read(2352)

			# now sort the array and see if the new read value has enough matches
			# right index minus left index of the read value is amount of matches
			@errors[start_chunk].sort!
			if (@errors[start_chunk].rindex(temp) - @errors[start_chunk].index(temp)) == (@reqMatchesErrors - 1)
				file1.pos = start_chunk + 44
				file1.write(temp)
				@errors.delete(start_chunk)
			end
		end

		file1.close
		file2.close

		# Remove the file now we read it. Differences are saved in memory.
		File.delete(@settings['Out'].getTempFile(track, @trial))
		
		#give an update of the amount of errors and trials
		if @errors.size == 0
			@settings['log'].add(_("Error(s) succesfully corrected, %s matches found for each chunk :)\n") % [@reqMatchesErrors])
		else
			@settings['log'].mismatch(track, @trial, @errors.keys, @settings['cd'].getFileSize(track), @settings['cd'].getLengthSector(track)) # report for later position analysis
			@settings['log'].add(_("%s chunk(s) didn't match %s times.\n") % [@errors.length, @reqMatchesErrors])
		end
	end
	
	# add a timeout if a disc takes longer than 30 minutes to rip (this might save the hardware and the disc)
	def cooldownNeeded
		puts "Minutes ripping is #{(Time.now - @timeStarted) / 60}." if @settings['debug']
		
		if (((Time.now - @timeStarted) / 60) > 30 && @settings['maxThreads'] != 0)
			@settings['log'].add(_("The drive is spinning for more than 30 minutes.\n"))
			@settings['log'].add(_("Taking a timeout of 2 minutes to protect the hardware.\n"))
			sleep(120)
			@timeStarted = Time.now # reset time
		end
	end
	
	def rip(track) # set cdparanoia command + parameters
		cooldownNeeded()

		timeStarted = Time.now
		
		if track == "image"
			@settings['log'].add(_("Starting to rip CD image, trial \#%s") % [@trial])
		else
			@settings['log'].add(_("Starting to rip track %s, trial \#%s") % [track, @trial])
		end

		command = "cdparanoia"
		
		if @settings['rippersettings'].size != 0
			command += " #{@settings['rippersettings']}"
		end 
		
		command += " [.#{@settings['cd'].getStartSector(track)}]-"

		# for the last track tell cdparanoia to rip till end to prevent problems on some drives
		if track != "image" && track != @settings['cd'].audiotracks
			command += "[.#{@settings['cd'].getLengthSector(track) - 1}]"
		end

		 # the ported cdparanoia for MacOS misses the -d option, default drive will be used.
		if @settings['cd'].multipleDriveSupport ; command += " -d #{@settings['cdrom']}" end

		command += " -O #{@settings['offset']}"
		command += " \"#{@settings['Out'].getTempFile(track, @trial)}\""
		unless @settings['verbose'] ; command += " 2>&1" end # hide the output of cdparanoia output
		puts command if @settings['debug']
		`#{command}` if @cancelled == false #Launch the cdparanoia command
		@settings['log'].add(" (#{(Time.now - timeStarted).to_i} #{_("seconds")})\n")
	end
	
	def getDigest(track)
		digest = Digest::MD5.new()
		file = File.open(@settings['Out'].getTempFile(track, 1), 'r')
		index = 0
		while (index < @settings['cd'].getFileSize(track))
			digest << file.read(100000)
			index += 100000
		end
		file.close()
		@settings['log'].add(_("MD5 sum: %s\n\n") % [digest.hexdigest])
	end
end

class Encode
	attr_writer :cancelled
	
	require 'thread'
	
	def initialize(settings)
		@settings = settings
		@cancelled = false
		@progress = 0.0
		@threads = []
		@queue = SizedQueue.new(@settings['maxThreads']) if @settings['maxThreads'] != 0
		@lock = Monitor.new
		@out = @settings['Out'] # create a shortcut

		# Set the charset environment variable to UTF-8. Oggenc needs this.
		# Perhaps others need it as well.
		ENV['CHARSET'] = "UTF-8" 
		
		@codecs = 0 # number of codecs
		['flac','vorbis','mp3','wav','other'].each do |codec|
			@codecs += 1 if @settings[codec]
		end

		# all encoding tasks are saved here, to determine when to delete a wav
		@tasks = Hash.new
		@settings['tracksToRip'].each{|track| @tasks[track] = @codecs}
	end
	
	# is called when a track is ripped succesfully
	def addTrack(track)
		if normalize(track)
			startEncoding(track)
		end
	end

	# encode track when normalize is finished
	def startEncoding(track)
		# mark the progress bar as being started
		@settings['log'].encPerc(0.0) if track == @settings['tracksToRip'][0]
		['flac', 'vorbis', 'mp3', 'wav', 'other'].each do |codec|
			if @settings[codec] && @cancelled == false
				if @settings['maxThreads'] == 0
					encodeTrack(track,codec)
				else
					puts "Adding track #{track} (#{codec}) to the queue.." if @settings['debug']
					@queue << 1 # add a value to the queue, if full wait here.
					@threads << Thread.new do
						encodeTrack(track,codec)
						puts "Removing track #{track} (#{codec}) from the queue.." if @settings['debug']
						@queue.shift() # move up in the queue to the first waiter
					end
				end
			end
		end
		
		#give the signal we're finished
		if track == @settings['tracksToRip'][-1] && @cancelled == false
			@threads.each{|thread| thread.join()}	
			finished()
		end
	end

	# respect the normalize setting
	def normalize(track)
		continue = true
		if @settings['normalize'] != 'normalize'
		elsif !installed('normalize')
			puts "WARNING: normalize is not installed on your system!"
		elsif @settings['gain'] == 'album' && @settings['tracksToRip'][-1] == track
			command = "normalize -b \"#{File.join(@out.getTempDir(),'*.wav')}\""
			`#{command}`
			# now the wavs are altered, the encoding can start
			@settings['tracksToRip'].each{|track| startEncoding(track)}
			continue = false
		elsif @settings['gain'] == 'track'
			command = "normalize \"#{@out.getTempFile(track, 1)}\""
			`#{command}`
		end
		return continue
	end
	
	# call the specific codec function for the track
	def encodeTrack(track, codec)
		if codec == 'flac' ; doFlac(track)
		elsif codec == 'vorbis' ; doVorbis(track)
		elsif codec == 'mp3' ; doMp3(track)
		elsif codec == 'wav' ; doWav(track)
		elsif codec == 'other' && @settings['othersettings'] != nil ; doOther(track)
		end
		
		@lock.synchronize do
			File.delete(@out.getTempFile(track, 1)) if (@tasks[track] -= 1) == 0
			updateProgress(@settings['percentages'][track] / @codecs)
		end
	end

	# update the gui
	def updateProgress(progress)
		@progress += progress
		@settings['log'].encPerc(@progress)
	end

	
	def finished
		puts "Inside the finished function" if @settings['debug']
		@progress = 1.0 ; @settings['log'].encPerc(@progress)
		@settings['log'].summary(@settings['req_matches_all'], @settings['req_matches_errors'], @settings['max_tries'])
		if @settings['no_log'] ; @settings['log'].delLog end #Delete the logfile if no correction was needed if no_log is true
		@out.cleanTempDir()
		if (@settings['log'].rippingErrors || @settings['log'].encodingErrors)
			@settings['instance'].update("finished", false)
		else
			@settings['instance'].update("finished", true)
		end
	end
	
	def replaygain(filename, codec, track)
		if @settings['normalize'] == "replaygain"
			command = ''
			if @settings['gain'] == "album" && @settings['tracksToRip'][-1] == track || @settings['gain']=="track"
				if codec == 'flac' && installed('metaflac')
					command = "metaflac --add-replay-gain \"#{if @settings['gain'] =="track" ; filename else File.dirname(filename) + "\"/*.flac" end}"
				elsif codec == 'vorbis' && installed('vorbisgain')
					command = "vorbisgain #{if @settings['gain'] =="track" ; "\"" + filename + "\"" else "-a \"" + File.dirname(filename) + "\"/*.ogg" end}"
				elsif codec == 'mp3' && installed('mp3gain') && @settings['gainTagsOnly']
					command = "mp3gain -c #{if @settings['gain'] =="track" ; "\"" + filename + "\"" else "\"" + File.dirname(filename) + "\"/*.mp3" end}"
				elsif codec == 'mp3' && installed('mp3gain') && !@settings['gainTagsOnly']
					command = "mp3gain -c #{if @settings['gain'] =="track" ; "-r \"" + filename + "\"" else "-a \"" + File.dirname(filename) + "\"/*.mp3" end}"
				elsif codec == 'wav' && installed('wavegain')
					command = "wavegain #{if @settings['gain'] =="track" ; "\"" + filename +"\"" else "-a \"" + File.dirname(filename) + "\"/*.wav" end}"
				end
			end
			`#{command}` if command != ''
		end
	end

	def doFlac(track)
		filename = @out.getFile(track, 'flac')
		if !@settings['flacsettings'] ; @settings['flacsettings'] = '--best' end
		flac(filename, track)
		replaygain(filename, 'flac', track)
	end
		
	def doVorbis(track)
		filename = @out.getFile(track, 'vorbis')
		if !@settings['vorbissettings'] ; @settings['vorbissettings'] = '-q 6' end
		vorbis(filename, track)
		replaygain(filename, 'vorbis', track)
	end
		
	def doMp3(track)
		@possible_lame_tags = ['A CAPPELLA', 'ACID', 'ACID JAZZ', 'ACID PUNK', 'ACOUSTIC', 'ALTERNATIVE', 'ALT. ROCK', 'AMBIENT', 'ANIME', 'AVANTGARDE', \
'BALLAD', 'BASS', 'BEAT', 'BEBOB', 'BIG BAND', 'BLACK METAL', 'BLUEGRASS', 'BLUES', 'BOOTY BASS', 'BRITPOP', 'CABARET', 'CELTIC', 'CHAMBER MUSIC', 'CHANSON', \
'CHORUS', 'CHRISTIAN GANGSTA RAP', 'CHRISTIAN RAP', 'CHRISTIAN ROCK', 'CLASSICAL', 'CLASSIC ROCK', 'CLUB', 'CLUB-HOUSE', 'COMEDY', 'CONTEMPORARY CHRISTIAN', \
'COUNTRY', 'CROSSOVER', 'CULT', 'DANCE', 'DANCE HALL', 'DARKWAVE', 'DEATH METAL', 'DISCO', 'DREAM', 'DRUM & BASS', 'DRUM SOLO', 'DUET', 'EASY LISTENING', \
'ELECTRONIC', 'ETHNIC', 'EURODANCE', 'EURO-HOUSE', 'EURO-TECHNO', 'FAST-FUSION', 'FOLK', 'FOLKLORE', 'FOLK/ROCK', 'FREESTYLE', 'FUNK', 'FUSION', 'GAME', \
'GANGSTA RAP', 'GOA', 'GOSPEL', 'GOTHIC', 'GOTHIC ROCK', 'GRUNGE', 'HARDCORE', 'HARD ROCK', 'HEAVY METAL', 'HIP-HOP', 'HOUSE', 'HUMOUR', 'INDIE', 'INDUSTRIAL', \
'INSTRUMENTAL', 'INSTRUMENTAL POP', 'INSTRUMENTAL ROCK', 'JAZZ', 'JAZZ+FUNK', 'JPOP', 'JUNGLE', 'LATIN', 'LO-FI', 'MEDITATIVE', 'MERENGUE', 'METAL', 'MUSICAL', \
'NATIONAL FOLK', 'NATIVE AMERICAN', 'NEGERPUNK', 'NEW AGE', 'NEW WAVE', 'NOISE', 'OLDIES', 'OPERA', 'OTHER', 'POLKA', 'POLSK PUNK', 'POP', 'POP-FOLK', 'POP/FUNK', \
'PORN GROOVE', 'POWER BALLAD', 'PRANKS', 'PRIMUS', 'PROGRESSIVE ROCK', 'PSYCHEDELIC', 'PSYCHEDELIC ROCK', 'PUNK', 'PUNK ROCK', 'RAP', 'RAVE', 'R&B', 'REGGAE', \
'RETRO', 'REVIVAL', 'RHYTHMIC SOUL', 'ROCK', 'ROCK & ROLL', 'SALSA', 'SAMBA', 'SATIRE', 'SHOWTUNES', 'SKA', 'SLOW JAM', 'SLOW ROCK', 'SONATA', 'SOUL', 'SOUND CLIP', \
'SOUNDTRACK', 'SOUTHERN ROCK', 'SPACE', 'SPEECH', 'SWING', 'SYMPHONIC ROCK', 'SYMPHONY', 'SYNTHPOP', 'TANGO', 'TECHNO', 'TECHNO-INDUSTRIAL', 'TERROR', 'THRASH METAL', \
'TOP 40', 'TRAILER', 'TRANCE', 'TRIBAL', 'TRIP-HOP', 'VOCAL']
		filename = @out.getFile(track, 'mp3')
		if !@settings['mp3settings'] ; @settings['mp3settings'] = "--preset fast standard" end
		
		# lame versions before 3.98 didn't support other genre tags than the 
		# ones defined above, so change it to 'other' to prevent crashes
		lameVersion = `lame --version`[20,4].split('.') # for example [3, 98]
		if (lameVersion[0] == '3' && lameVersion[1].to_i < 98 && 
		!@possible_lame_tags.include?(@out.genre.upcase))
		    genre = 'other' 
		else
		    genre = @out.genre
		end
		
		mp3(filename, genre, track)
		replaygain(filename, 'mp3', track)
	end
		
	def doWav(track)
		filename = @out.getFile(track, 'wav')
		wav(filename, track)
		replaygain(filename, 'wav', track)
	end

	def doOther(track)
		filename = @out.getFile(track, 'other')
		command = @settings['othersettings'].dup

		command.force_encoding("UTF-8") if command.respond_to?("force_encoding")
		command.gsub!('%n', sprintf("%02d", track)) if track != "image"
		command.gsub!('%f', 'other')

		if @out.getVarArtist(track) != ''
			command.gsub!('%a', @out.getVarArtist(track))
			command.gsub!('%va', @out.artist)
		else
			command.gsub!('%a', @out.artist)
		end

		command.gsub!('%b', @out.album)
		command.gsub!('%g', @out.genre)
		command.gsub!('%y', @out.year)
		command.gsub!('%t', @out.getTrackname(track))
		command.gsub!('%i', @out.getTempFile(track, 1))
		command.gsub!('%o', @out.getFile(track, 'other'))
		checkCommand(command, track, 'other')
	end
	
	def flac(filename, track)
		tags = String.new
		tags.force_encoding("UTF-8") if tags.respond_to?("force_encoding")
		tags += "--tag ALBUM=\"#{@out.album}\" "
		tags += "--tag DATE=\"#{@out.year}\" "
		tags += "--tag GENRE=\"#{@out.genre}\" "
		tags += "--tag DISCID=\"#{@settings['cd'].discId}\" "
		tags += "--tag DISCNUMBER=\"#{@settings['cd'].md.discNumber}\" " if @settings['cd'].md.discNumber
		
		 # Handle tags for single file images differently
		if @settings['image']
			tags += "--tag ARTIST=\"#{@out.artist}\" " #artist is always artist
			if @settings['create_cue'] # embed the cuesheet
				tags += "--cuesheet=\"#{@out.getCueFile('flac')}\" "
			end
		else # Handle tags for var artist discs differently
			if @out.getVarArtist(track) != ''
				tags += "--tag ARTIST=\"#{@out.getVarArtist(track)}\" "
				tags += "--tag \"ALBUM ARTIST\"=\"#{@out.artist}\" "
			else
				tags += "--tag ARTIST=\"#{@out.artist}\" "
			end
			tags += "--tag TITLE=\"#{@out.getTrackname(track)}\" "
			tags += "--tag TRACKNUMBER=#{track} "
			tags += "--tag TRACKTOTAL=#{@settings['cd'].audiotracks} "			
		end

		command = String.new
		command.force_encoding("UTF-8") if command.respond_to?("force_encoding")
		command +="flac #{@settings['flacsettings']} -o \"#{filename}\" #{tags}\
\"#{@out.getTempFile(track, 1)}\""
		command += " 2>&1" unless @settings['verbose']

		checkCommand(command, track, 'flac')
	end
	
	def vorbis(filename, track)
		tags = String.new
		tags.force_encoding("UTF-8") if tags.respond_to?("force_encoding")
		tags += "-c ALBUM=\"#{@out.album}\" "
		tags += "-c DATE=\"#{@out.year}\" "
		tags += "-c GENRE=\"#{@out.genre}\" "
		tags += "-c DISCID=\"#{@settings['cd'].discId}\" "
		tags += "-c DISCNUMBER=\"#{@settings['cd'].md.discNumber}\" " if @settings['cd'].md.discNumber

		 # Handle tags for single file images differently
		if @settings['image']
			tags += "-c ARTIST=\"#{@out.artist}\" "
		else # Handle tags for var artist discs differently
			if @out.getVarArtist(track) != ''
				tags += "-c ARTIST=\"#{@out.getVarArtist(track)}\" "
				tags += "-c \"ALBUM ARTIST\"=\"#{@out.artist}\" "
			else
				tags += "-c ARTIST=\"#{@out.artist}\" "
			end
			tags += "-c TITLE=\"#{@out.getTrackname(track)}\" "
			tags += "-c TRACKNUMBER=#{track} "
			tags += "-c TRACKTOTAL=#{@settings['cd'].audiotracks}"
		end

		command = String.new
		command.force_encoding("UTF-8") if command.respond_to?("force_encoding")
		command += "oggenc -o \"#{filename}\" #{@settings['vorbissettings']} \
#{tags} \"#{@out.getTempFile(track, 1)}\""
		command += " 2>&1" unless @settings['verbose']
	
		checkCommand(command, track, 'vorbis')
	end
	
	def mp3(filename, genre, track)
		tags = String.new
		tags.force_encoding("UTF-8") if tags.respond_to?("force_encoding")
		tags += "--tl \"#{@out.album}\" "
		tags += "--ty \"#{@out.year}\" "
		tags += "--tg \"#{@out.genre}\" "
		tags += "--tv TXXX=DISCID=\"#{@settings['cd'].discId}\" "
		tags += "--tv TPOS=\"#{@settings['cd'].md.discNumber}\" " if @settings['cd'].md.discNumber

		 # Handle tags for single file images differently
		if @settings['image']
			tags += "--ta \"#{@out.artist}\" "
		else # Handle tags for var artist discs differently
			if @out.getVarArtist(track) != ''
				tags += "--ta \"#{@out.getVarArtist(track)}\" "
				tags += "--tv \"ALBUM ARTIST\"=\"#{@out.artist}\" "
			else
				tags += "--ta \"#{@out.artist}\" "
			end
			tags += "--tt \"#{@out.getTrackname(track)}\" "
			tags += "--tn #{track}/#{@settings['cd'].audiotracks} "
		end

		# set UTF-8 tags (not the filename) to latin because of a lame bug.
		begin
			require 'iconv'
			tags = Iconv.conv("ISO-8859-1", "UTF-8", tags)		
		rescue
			puts "couldn't convert to ISO-8859-1 succesfully"
		end

		# combining two encoding sets in binary mode, only needed for ruby >=1.9
		command = String.new
		inputWavFile = @out.getTempFile(track, 1)
		if command.respond_to?("force_encoding")
			command.force_encoding("ASCII-8BIT")
			tags.force_encoding("ASCII-8BIT")
			inputWavFile.force_encoding("ASCII-8BIT")
			filename.force_encoding("ASCII-8BIT")
		end

		command += "lame #{@settings['mp3settings']} #{tags}\"\
#{inputWavFile}\" \"#{filename}\""
		command += " 2>&1" unless @settings['verbose']
	
		checkCommand(command, track, 'mp3')
	end
	
	def wav(filename, track)
		begin
			FileUtils.cp(@out.getTempFile(track, 1), filename)
		rescue
			puts "Warning: wav file #{@out.getTempFile(track,1)} not found!"
			puts "If this is not the case, you might have a shortage of disk space.."
		end
	end
	
	def checkCommand(command, track, codec)
		puts "command = #{command}" if @settings['debug']

		exec = IO.popen("nice -n 6 #{command}") #execute command
		exec.readlines() #get all the output
		
		if Process.waitpid2(exec.pid)[1].exitstatus != 0
			@settings['log'].add(_("WARNING: Encoding to %s exited with an error with track %s!\n") % [codec, track])
			@settings['log'].encodingErrors = true
		end
	end
end

class Rubyripper
attr_reader :outputDir
	
	def initialize(settings, gui)
		@settings = settings.dup
		@directory = false
		@settings['log'] = false
		@settings['instance'] = gui
		@error = false
		@encoding = nil
		@ripping = nil
		@warnings = Array.new
	end
	
	def settingsOk
		if not checkConfig() ; return @error end
		if not testDeps() ; return @error end
		getWarnings()
		@settings['cd'].md.saveChanges()
		@settings['Out'] = Output.new(@settings)
		return @settings['Out'].status
	end
	
	def startRip
		@settings['log'] = Gui_support.new(@settings)
		@outputDir = @settings['Out'].getDir()
		updateGui() # Give some info about the cdrom-player, the codecs, the ripper, cddb_info

		waitForToc()

		@settings['log'].add(_("\nSTATUS\n\n"))
		
		computePercentage() # Do some pre-work to get the progress updater working later on
		require 'digest/md5' # Needed for secure class, only have to load them ones here.
		@encoding = Encode.new(@settings) #Create an instance for encoding
		@ripping = SecureRip.new(@settings, @encoding) #create an instance for ripping
	end

	# the user wants to abort the ripping	
	def cancelRip
		puts "User aborted current rip"
		`killall cdrdao 2>&1`
		@encoding.cancelled = true if @encoding != nil
		@encoding = nil
		@ripping.cancelled = true if @ripping != nil
		@ripping = nil
		`killall cdparanoia 2>&1` # kill any rip that is already started
	end

	# wait for the Advanced Toc class to finish
	# cdrdao takes a while to finish reading the disc
	def waitForToc
		if @settings['create_cue'] && installed('cdrdao')
			@settings['log'].add(_("\nADVANCED TOC ANALYSIS (with cdrdao)\n"))
			@settings['log'].add(_("...please be patient, this may take a while\n\n"))
		
			@settings['cd'].updateSettings(@settings) # update the rip settings
			
			@settings['cd'].toc.log.each do |message|
				@settings['log'].add(message)
			end
		end
	end
	
	# check the configuration of the user.
	# 1) does the ripping drive exists
	# 2) are there tracks selected to rip
	# 3) is the current disc the same as loaded in memory
	# 4) is at least one codec is selected
	# 5) are the otherSettings correct
	# 6) is req_matches_all <= req_matches_errors

	def checkConfig
		unless File.symlink?(@settings['cdrom']) || File.blockdev?(@settings['cdrom'])
			@error = ["error", _("The device %s doesn't exist on your system!") % [@settings['cdrom']]]
			return false
		end

		if @settings['tracksToRip'].size == 0
			@error = ["error", _("Please select at least one track.")]
			return false
		end
		
		if (!@settings['cd'].tocStarted || @settings['cd'].tocFinished)
			temp = Disc.new(@settings, @settings['instance'], '', true)
			if @settings['cd'].freedbString != temp.freedbString || @settings['cd'].playtime != temp.playtime
				@error = ["error", _("The Gui doesn't match inserted cd. Please press Scan Drive first.")]
 				return false
			end
		end
		
		unless @settings['flac'] || @settings['vorbis'] || @settings['mp3'] || @settings['wav'] || @settings['other']
			@error = ["error", _("No codecs are selected!")]
			return false
 		end

		# filter out encoding flags that do non-encoding tasks
		@settings['flacsettings'].gsub!(' --delete-input-file', '')

		if @settings['other'] ; checkOtherSettings() end
			
		# update the ripping settings for a hidden audio track if track 1 is selected
		if @settings['cd'].getStartSector(0) && @settings['tracksToRip'][0] == 1
			@settings['tracksToRip'].unshift(0)
		end
 		
 		if @settings['req_matches_all'] > @settings['req_matches_errors'] ; @settings['req_matches_errors'] = @settings['req_matches_all'] end
		return true
	end

	def checkOtherSettings
		copyString = ""
		lastChar = ""
		
		#first remove all double quotes. then iterate over each char
		@settings['othersettings'].delete('"').split(//).each do |char|
			if char == '%' # prepend double quote before %
				copyString << '"' + char
			elsif lastChar == '%' # append double quote after %char
				copyString << char + '"'
			else
				copyString << char
			end
			lastChar = char
		end

		# above won't work for various artist
		copyString.gsub!('"%v"a', '"%va"')

		@settings['othersettings'] = copyString

		puts @settings['othersettings'] if @settings['debug']
	end
	
	def testDeps
		{"ripper" => "cdparanoia", "flac" => "flac", "vorbis" => "oggenc", "mp3" => "lame"}.each do |setting, binary|
			if @settings[setting] && !installed(binary)
				@error = ["error", _("%s not found on your system!") % [binary.capitalize]]
				return false
			end
		end
		return true
	end

	# check for some non-blocking problems
	def getWarnings
		if @settings['normalize'] == 'normalize' && !installed('normalize')
			@warnings << _("WARNING: Normalize is not installed!\n")
		end

		if @settings['normalize'] == 'replaygain'
			if @settings['flac'] && !installed('metaflac')
				@warnings << _("WARNING: Replaygain for flac (metaflac) not installed!\n")
			end

			if @settings['vorbis'] && !installed('vorbisgain')
				@warnings << _("WARNING: Replaygain for vorbis (vorbisgain) not installed!\n")
			end

			if @settings['mp3'] && !installed('mp3gain')
				@warnings << _("WARNING: Replaygain for mp3 (mp3gain) not installed!\n")
			end

			if @settings['wav'] && !installed('wavegain')
				@warnings << _("WARNING: Replaygain for wav (wavegain) not installed!\n")
			end
		end
	end

	def summary
		return @settings['log'].short_summary
	end

	def postfixDir
		@settings['Out'].postfixDir()
	end

	def overwriteDir
		@settings['Out'].overwriteDir()
	end

	def updateGui
		@settings['log'].add(_("Cdrom player used to rip:\n%s\n") % [@settings['cd'].devicename])
		@settings['log'].add(_("Cdrom offset used: %s\n\n") % [@settings['offset']])
		@settings['log'].add(_("Ripper used: cdparanoia %s\n") % [if @settings['rippersettings'] ; @settings['rippersettings'] else _('default settings') end])
		@settings['log'].add(_("Matches required for all chunks: %s\n") % [@settings['req_matches_all']])
		@settings['log'].add(_("Matches required for erroneous chunks: %s\n\n") % [@settings['req_matches_errors']])
		
		@warnings.each{|warning| @settings['log'].add(warning)}
		@settings['log'].add(_("Codec(s) used:\n"))
		if @settings['flac']; @settings['log'].add(_("-flac \t-> %s (%s)\n") % [@settings['flacsettings'], `flac --version`.strip]) end
		if @settings['vorbis']; @settings['log'].add(_("-vorbis\t-> %s (%s)\n") % [@settings['vorbissettings'], `oggenc --version`.strip]) end
		if @settings['mp3']; @settings['log'].add(_("-mp3\t-> %s\n(%s\n") % [@settings['mp3settings'], `lame --version`.split("\n")[0]]) end
		if @settings['wav']; @settings['log'].add(_("-wav\n")) end
		if @settings['other'] ; @settings['log'].add(_("-other\t-> %s\n") % [@settings['othersettings']]) end
		@settings['log'].add(_("\nCDDB INFO\n"))
		@settings['log'].add(_("\nArtist\t= "))
		@settings['log'].add(@settings['cd'].md.artist)
		@settings['log'].add(_("\nAlbum\t= "))
		@settings['log'].add(@settings['cd'].md.album)
		@settings['log'].add(_("\nYear\t= ") + @settings['cd'].md.year)
		@settings['log'].add(_("\nGenre\t= ") + @settings['cd'].md.genre)
		@settings['log'].add(_("\nTracks\t= ") + @settings['cd'].audiotracks.to_s + 
		" (#{@settings['tracksToRip'].length} " + _("selected") + ")\n\n")
		@settings['cd'].audiotracks.times do |track|
			if @settings['tracksToRip'] == 'image' || @settings['tracksToRip'].include?(track + 1)
				@settings['log'].add("#{sprintf("%02d", track + 1)} - #{@settings['cd'].md.tracklist[track]}\n")	
			end
		end
	end
	
	def computePercentage
		@settings['percentages'] = Hash.new() #progress for each track
		totalSectors = 0.0 # It can be that the user doesn't want to rip all tracks, so calculate it
		@settings['tracksToRip'].each{|track| totalSectors += @settings['cd'].getLengthSector(track)} #update totalSectors
		@settings['tracksToRip'].each{|track| @settings['percentages'][track] = @settings['cd'].getLengthSector(track) / totalSectors}
	end
end
