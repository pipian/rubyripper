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

$rr_version = '0.5.7' #application wide setting

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

require 'monitor' #help library for threaded applications
require 'yaml' #help library to save data structures into files

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

def cdrom_drive #default values for cdrom drives under differenty os'es
	drive = 'Unknown!'
	system = RUBY_PLATFORM
	if system.include?('openbsd')
		drive = '/dev/cd0c' # as provided in issue 324
	elsif system.include?('linux') || system.include?('bsd')
		drive = '/dev/cdrom'
	elsif system.include?('darwin')
		drive = '/dev/disk1'
	elsif system.include?('win') # no support for Windows as of yet, but keeping possibilities open for the future
		drive = 'cdaudio'
	end
	return drive
end

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

def browser
	if ENV['DESKTOP_SESSION'] == 'kde' && installed('konqueror')
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

$rr_defaultSettings = {"flac" => false, "flacsettings" => "--best -V", "vorbis" => true, "vorbissettings" => "-q 4", "mp3" => false, "mp3settings" => "-V 3 --id3v2-only", "wav" => false, "other" => false, "othersettings" => '', "playlist" => true, "cdrom" => cdrom_drive(), "offset" => 0, "maxThreads" => 2, "rippersettings" => '', "max_tries" => 5, 'basedir' => '~/', 'naming_normal' => '%f/%a (%y) %b/%n - %t', 'naming_various' => '%f/%a (%y) %b/%n - %va - %t', 'naming_image' => '%f/%a (%y) %b/%a - %b (%y)', "verbose" => false, "debug" => true, "instance" => self, "eject" => true, "req_matches_errors" => 2, "req_matches_all" => 2, "site" => "http://freedb2.org:80/~cddb/cddb.cgi", "username" => "anonymous", "hostname" => "my_secret.com", "first_hit" => true, "freedb" => true, "editor" => editor(), "filemanager" => filemanager(), "no_log" =>false, "create_cue" => false, "image" => false, 'normalize' => false, 'gain' => "album", 'noSpaces' => false, 'noCapitals' => false}

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
	{'%a' => 'Various Artists', '%b' => 'TMF Rockzone', '%f' => 'codec', '%g' => "Rock", '%y' => '1999', '%n' => '01', '%va' => 'Kid Rock', '%t' => 'Cowboy'}.each{|key, value| filename.gsub!(key,value)}
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

class Gui_support
attr_reader :ripPerc, :encPerc, :add, :summary, :ripping_progress, :encoding_progress, :mismatch, :short_summary, :delLog
attr_writer :encodingErrors

	def initialize(settings) #gui is an instance of the graphical user interface used
		@settings = settings
		createLog()
		
		@problem_tracks = Hash.new # key = tracknumber, value = new dictionary with key = seconds_chunk, value = [amount_of_chunks, trials_needed]
		@not_corrected_tracks = Array.new # Array of tracks that weren't corrected within the maximum amount of trials set by the user
		@ripping_progress = 0.0
		@encoding_progress = 0.0
		@encodingErrors = false
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

class AdvancedTOC
	def initialize(settings)
		@settings = settings
		# scan the disc for pregaps
		`cdrdao read-toc --device #{@settings['cdrom']} #{File.join(@out.getTempDir(), 'output.toc')}`
		setVariables()
		parseTOC()
	end
	
	# initialize all variables
	def setVariables
		@discType = "CD_DA" #only audio
		@hiddenTrack = false
		@dataTracks = Array.new
		@preEmphasis = Hash.new
		@preGap = Hash.new
		@silence = 0 #amount of sectors at the start that can't be read by cdparanoia
		
		@artist = String.new
		@album = String.new
		@tracknames = Hash.new
	end

	# parse the disc info
	def parseTocDisc
		# read the output file, splitted by each newline, in an array
		toc = File.read(File.join(@out.getTempDir(), 'output.toc')).split("\n")
		
		# read the disc info
		@discType = @toc[0]
		
		# continue reading the disc until the track info starts
		index = 1
		while !toc[index].include?('//')
			if toc[index].include?('CD_TEXT')
				puts "Found cd_text for disc" if @settings['debug']
			elsif toc[index].include?('TITLE')
				@artist, @album = @toc[index].split(/\s\s+/)
				puts "Found artist for disc: #{@artist}" if @settings['debug']
				puts "Found album for disc: #{@album}" if @settings['debug']
			end
			index += 1
		end
		
		parseTocTrack(toc, index)
	end

	# read the track info
	def parseTocTrack(toc, index)
		tracknumber = 0
		while (index + 1) != toc.size
			if toc[index].include?('//')
				tracknumber += 1
				puts "Found info of tracknumber #{tracknumber}" if @settings['debug']
			elsif toc[index].include?('TRACK DATA')
				@dataTracks << tracknumber
				puts "Track #{tracknumber} is marked as a DATA track" if @settings['debug']
			elsif toc[index] == 'PRE_EMPHASIS'
				@preEmphasis[tracknumber] = true
				puts "Pre_emphasis detected on track #{tracknumber}" if @settings['debug']
			elsif toc[index].include?('START')
				sectorMinutes = 75 * toc[index][9..10].to_i
				@pregap[tracknumber] = sectorMinutes + toc[index][12..13].to_i
				puts "Pregap detected for track #{tracknumber} : #{@pregap[tracknumber]} sectors}" if @settings['debug']
			elsif toc[index].include?('SILENCE')
				sectorMinutes = 75 * toc[index][11..12].to_i
				@silence = sectorMinutes + toc[index][14..15].to_i
				puts "Silence detected for track #{tracknumber} : #{@silence} sectors}" if @settings['debug']
			elsif toc[index].include?('TITLE')
				toc[index] =~ /".*"/ #ruby's  magical regular expressions
				@tracknames[tracknumber] = $&[1..-2] #don't need the quotes
				puts "CD-text found: Title = #{@tracknames[tracknumber]}" if @settings['debug']
			end
		end
	end
end

class Cuesheet

# INFO -> TRACK 01 = Start point of track hh:mm:ff (h =hours, m = minutes, f = frames
# INFO -> After each FILE entry should follow the format. Only WAVE and MP3 are allowed AND relevant.

	def initialize(settings, out)
		@settings = settings
		@out = out
		@disc = settings['cd']
		@image = settings['image']
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
		@cuesheet << "REM GENRE #{@disc.md.genre}"
		@cuesheet << "REM DATE #{@disc.md.year}"
		@cuesheet << "REM COMMENT \"Rubyripper #{$rr_version}\""
		@cuesheet << "REM DISCID #{@disc.discId}"
		@cuesheet << "REM FREEDB_QUERY \"#{@disc.freedbString.chomp}\""
		@cuesheet << "PERFORMER \"#{@disc.md.artist}\""
		@cuesheet << "TITLE \"#{@disc.md.album}\""

		if @image == true
			@cuesheet << "FILE \"#{@out.getFile('1', @codec)}\" #{@filetype[@codec]}"
			@disc.audiotracks.times{|track| trackinfo(track)}
		else
			@disc.audiotracks.times do |track|
				@cuesheet << "FILE \"#{File.basename(@out.getFile(track + 1, @codec))}\" #{@filetype[@codec]}"
				trackinfo(track)
			end
		end
	end

	def trackinfo(track)
		@cuesheet << "  TRACK #{sprintf("%02d", track + 1)} AUDIO"
		@cuesheet << "    TITLE \"#{@disc.md.tracklist[track]}\""
		if @disc.md.varArtists.empty?
			@cuesheet << "    PERFORMER \"#{@disc.md.artist}\""
		else
			@cuesheet << "    PERFORMER \"#{@disc.md.varArtists[track]}\""
		end

		if @disc.pregap[track] != 0 && @image
			@cuesheet << "    INDEX 00 #{time(@disc.startSector[track] - @disc.pregap[track])}"
		elsif @disc.pregap[track] != 0
			@cuesheet << "    INDEX 00 00:00:00"
		end

		if @image
			@cuesheet << "    INDEX 01 #{time(@disc.startSector[track])}"
		else
			@cuesheet << "    INDEX 01 #{time(@disc.pregap[track])}"
		end
	end

	def saveCuesheet
		file = File.new(@out.getCueFile(@codec), 'w')
		@cuesheet.each do |line|
			file.puts(line)
		end
		file.close()
	end
end

class Disc
attr_reader :cdrom, :multipleDriveSupport, :audiotracks, :lengthSector, 
:startSector, :lengthText, :devicename, :playtime, :freedbString, 
:oldFreedbString, :pregap, :postgap, :totalSectors, :md, :error, :fileSizeWav,
:fileSizeDisc, :discId

	def initialize(cdrom='/dev/cdrom', freedb = true, gui=false, verbose=false, oldFreedbString = '')
		@cdrom = cdrom
		@freedb = freedb
		@oldFreedbString = oldFreedbString #if new disc is the same, later on force a connection with the freedb server
		@gui = gui
		@verbose = verbose
		setVariables()
		if audioDisc()
			getDiscInfo()
			analyzeTOC() #table of contents
			@md = Metadata.new(self, @gui, @verbose)
		end
	end

	def setVariables
		@multipleDriveSupport = true #not always the case on MacOS's cdparanoia
		
		@audiotracks = 0
		@lengthSector = Array.new
		@startSector = Array.new
		@lengthText = Array.new
		@devicename = _("Unknown drive")
		@playtime = '00:00'

		@firstAudioTrack = 1 # some discs (games for instance) start with a data part
		@datatrack = false
		@freedbString = ''
		@discId = ''

		@pregap = Array.new
		@totalSectors = 0
		@fileSizeWav = Array.new
		@fileSizeDisc = 0
		
		@error = '' #set to the error messsage
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
				@lengthSector << lengthSector.to_i
				@startSector << startSector.to_i
				@lengthText << lengthText[1,5]
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
		if @query.include?('track_num = 176') # 176 = 0xb0 = end of data track??? # only MacOS version prints this
			startSector = @query.find_all{|line| line[0,9] == "track_num"}[0].split()[5].to_i
			lastSector = @query.find_all{|line| line[0,15] == 'track_num = 176'}[0].split()[5].to_i
		elsif installed('cd-info') #from the libcdio library
			@query = `cd-info -C #{@cdrom}`
			if @query.include?(' data ')
				startSector = @query.find_all{|line| line =~ /\s+data\s+/}[0].split()[2].to_i
				lastSector = @query.find_all{|line| line =~ /leadout/}[0].split()[2].to_i
			else
			    return false
			end
		else
			return false
		end	

		@datatrack = [startSector, lastSector-startSector]
	end

	def createFreedbString
		totalChecksum = 0
		seconds = 0
		freedbOffsets = ''
		totalSectors = 0
		audiotracks = @audiotracks + if @datatrack ; 1 else 0 end
		startSector = @startSector ; if @datatrack ;  startSector << @datatrack[0] end
		lengthSector = @lengthSector ; if @datatrack ; lengthSector << @datatrack[1] end

		audiotracks.times do |track|
			checksum = 0
			seconds = (startSector[track] + 150) / 75 # MSF offset = 150
			seconds.to_s.split(/\s*/).each{|s| checksum += s.to_i} # for example cddb sum of 338 seconds = 3+3+8=14
			totalChecksum += checksum
		end

		totalSectors = (startSector[-1] - startSector[0]) + lengthSector[-1]
		seconds = totalSectors / 75

		discid =  ((totalChecksum % 0xff) << 24 | seconds << 8 | audiotracks).to_s(16)
		startSector.each{|sector| freedbOffsets << (sector + 150).to_s + ' '}
		@freedbString = "#{discid} #{audiotracks} #{freedbOffsets}#{(totalSectors + 150) / 75}" # MSF offset = 150
	end

	def analyzeTOC
		@pregap << (@firstAudioTrack == 1 ? @startSector[0] : 0)

		(@audiotracks - 1).times do |track|
			@pregap << (@startSector[track+1] - (@startSector[track] + @lengthSector[track]))
		end

		@lengthSector.each{|track| @totalSectors += track}
		@pregap.each{|track| @totalSectors += track}
		
		# filesize = 44 bytes wav overhead + 2352 bytes per sector
		@audiotracks.times{|track| @fileSizeWav[track] = 44 + (@pregap[track] + @lengthSector[track]) * 2352}
		@fileSizeDisc = @totalSectors * 2352 + 44
	end
end

class Metadata
attr_reader :freedb, :rawResponse, :freedbChoice, :saveChanges, :undoVarArtist, :redoVarArtist, :status
attr_accessor :artist, :album, :genre, :year, :tracklist, :varArtists, :discNumber
	
	def initialize(disc, gui, verbose=false)
		@disc = disc
		@gui = gui
		@verbose = verbose
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
 		if File.exist?(metadataFile = File.join(ENV['HOME'], '.rubyripper/freedb.yaml'))
			@metadataFile = YAML.load(File.open(metadataFile))
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
						@rawResponse = File.read(File.join(dir, subdir, file))
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
		if not File.directory?(dirname = File.join(ENV['HOME'], '.rubyripper'))
			Dir.mkdir(dirname)
		end

		if File.exist?(filename = File.join(ENV['HOME'], '.rubyripper/freedb.yaml'))
			@metadataFile = YAML.load(File.open(filename))
		else
			@metadataFile = Hash.new
		end

		@metadataFile[@disc.freedbString] = @rawResponse
		
		file = File.new(filename, 'w')
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

	def checkVarArtist
		sep = ''
		varArtist = true
		separators = ['/', '-', 'by']
		separators.each do |sep|
			varArtist = sep
			@disc.audiotracks.times do |tracknumber|
				#if the separator is not found, search for the next separator
				if !@tracklist[tracknumber] || !@tracklist[tracknumber].include?(sep) 
					varArtist = false
					break
				end
			end
			if varArtist == sep ; break end
		end

		if varArtist != false
			@backupTracklist = @tracklist.dup() #backup before overwrite with new values
			@tracklist.each_index{|index| @varArtists[index], @tracklist[index] = @tracklist[index].split(/\s*#{sep}\s*/)} #remove any spaces (\s) around sep
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
attr_reader :getDir, :getFile, :getLogFile, :getCueFile,
:getTempDir, :getTempFile, :postfixDir, :overwriteDir, :status,
:cleanTempDir, :artist, :album, :year, :genre, :getTrackname, :getVarArtist
	
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
		@tracklist = Array.new
		@varArtists = Array.new
		
		splitDirFile()
		checkNames()
		setDirectory()
		attemptDirCreation()
	end

	# split the filescheme into a dir and a file
	def splitDirFile
		if @settings['image']
			fileScheme = File.join(@settings['basedir'], @settings['naming_image'])
		elsif @md.varArtists.empty?
			fileScheme =  File.join(@settings['basedir'], @settings['naming_normal'])
		else
			fileScheme = File.join(@settings['basedir'], @settings['naming_various'])
		end
		
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

		{'%a' => @artistFile, '%b' => @albumFile, '%f' => codec, '%g' => @md.genre,
		'%y' => @md.year}.each do |key, value|
			dirName.gsub!(key, value)
		end

		if @md.discNumber != false
			dirName = File.join(dirName, "CD #{sprintf("%02d", @md.discNumber)}")
		end
		
		return fileFilter(File.expand_path(dirName), true)
	end

	# (re)attempt creation of the dirs, when succesfull create the filenames
	def attemptDirCreation
		if not checkDirRights ; return false end
		if not checkDirExistence() ; return false end
		createDir()
		createTempDir()
		setMetadata()
		setFileNames()
		createFiles()
		@status = true
	end

	# create playlist + cuesheet files
	def createFiles
		['flac','vorbis','mp3','wav','other'].each do |codec|
			if @settings[codec] && @settings['playlist'] && !@settings['image']
				createPlaylist(codec)
			end
		end
		
		if @settings['create_cue']
			Cuesheet.new(@settings, self)
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
		require 'fileutils'
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
	end

	# give the filename for given codec and track
	def giveFileName(codec, track=0)
		file = @fileName.dup
		
		{'%a' => @md.artist, '%b' => @md.album, '%f' => codec, '%g' => @md.genre,
		'%y' => @md.year, '%n' => sprintf("%02d", track + 1), '%va' => getVarArtist(track + 1), 
		'%t' => getTrackname(track + 1)}.each do |key, value|
			file.gsub!(key, value)
		end

		# other codec has the extension already in the command
		if codec == 'flac' ; file += '.flac'
		elsif codec == 'vorbis' ; file += '.ogg'
		elsif codec == 'mp3' ; file += '.mp3'
		elsif codec == 'wav' ; file += '.wav'
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
			@tracklist << tagFilter(@md.tracklist[track])
		end
		if not @md.varArtists.empty?
			@settings['cd'].audiotracks.times do |track|
				@varArtists << tagFilter(@md.varArtists[track])
			end
		end
	end

	# characters that will be changed for filenames
	def fileFilter(var, isDir=false)
		if not isDir
			var.gsub!('/', '') #no slashes allowed in filenames
		end
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

		# replace utf-8 single quotes with latin single quote 
		var.gsub!(/\342\200\230|\342\200\231/, "'") 
		
		# replace utf-8 double quotes with latin double quote
		var.gsub!(/\342\200\234|\342\200\235/, '"') 
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
		if @settings['image']
			return File.join(@dir[codec], @image[codec])		
		else
			return File.join(@dir[codec], @file[codec][track])
		end	
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
		return File.join(getTempDir(), "track#{track}_#{trial}.wav")
	end

	#return the temporary dir
	def getTempDir
		return File.join(File.dirname(@dir.values[0]), "temp_#{@settings['cd'].discId}/")
	end

	#return the trackname for the metadata
	def getTrackname(track)
		if @tracklist[track - 1] == nil
			return ''
		else
			return @tracklist[track - 1]
		end
	end

	#return the artist for the metadata
	def getVarArtist(track)
		if @varArtists[track -1] == nil
			return ''
		else
			return @varArtists[track - 1]
		end
	end
end

class SecureRip
	def initialize(settings, encoding)
		@settings = settings
		@encoding = encoding
		@reqMatchesAll = @settings['req_matches_all'] # Matches needed for all chunks
		@reqMatchesErrors = @settings['req_matches_errors'] # Matches needed for chunks that didn't match immediately
		@progress = 0.0 #for the progressbar
		@sizeExpected = 0
		
		if @settings['maxThreads'] == 0 ; ripTracks() else Thread.new{ripTracks()} end
	end

	def ripTracks
		@settings['log'].ripPerc(0.0, "ripper") # Give a hint to the gui that ripping has started

		@settings['tracksToRip'].each do |track|
			puts "Ripping track #{track}" if @settings['debug']
		
			if @settings['offset'] != 0 && track == @settings['cd'].audiotracks && @settings['rippersettings'].include?('-Z') #workaround for bug in cdparanoia
				@settings['rippersettings'].gsub!(/-Z\s?/, '') #replace the -Z setting (and one space if it is there) with nothing. See issue nr. 13.
			end
			
			#reset next three variables for each track
			@errors = Hash.new()
			@filesizes = Array.new
			@trial = 0

			# first check if there's enough size available in the output dir
			if not sizeTest(track) ; break end

			if main(track) ; @encoding.addTrack(track) else return false end #ready to encode
		end
		
		eject(@settings['cd'].cdrom) if @settings['eject'] 
	end

	def sizeTest(track)
		if @settings['image']
			@sizeExpected = @settings['cd'].fileSizeDisc
		else
			@sizeExpected = @settings['cd'].fileSizeWav[track-1]
		end
		puts "Expected filesize for track #{track} is #{@sizeExpected} bytes." if @settings['debug'] 

		if installed('df')				
			freeDiskSpace = `LANG=C df \"#{@settings['Out'].getDir()}\"`.split()[10].to_i
			puts "Free disk space is #{freeDiskSpace} MB" if @settings['debug']
			if @sizeExpected > freeDiskSpace*1000
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
				@settings['log'].mismatch(track, 0, @errors.keys, @settings['cd'].fileSizeWav[track-1], @settings['cd'].lengthSector[track - 1]) # zero means it is never solved.
				break # break out loop and continue using trial1
			end
			
			doNewTrial(track)

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
		while true
			@trial += 1
			rip(track)
			if not fileCreated(track) ; return false end
			if not testFileSize(track) ; redo end
			break
		end
		return true
	end
	
	def fileCreated(track) #check if cdparanoia outputs wav files (passing bad parameters?)
		if not File.exist?(@settings['Out'].getTempFile(track, @trial))
			@settings['instance'].update("error", _("Cdparanoia doesn't output wav files.\nCheck your settings please."))
			return false
		end
		return true
	end
	
	def testFileSize(track) #check if wavfile is of correct size
		sizeRip = File.size(@settings['Out'].getTempFile(track, @trial))
		
		# at the end the disc may differ 1 sector on some drives (2352 bytes)
		if track == @settings['cd'].audiotracks && (@sizeExpected - sizeRip) == 2352
			puts "You have a buggy cdrom drive, last sector is skipped."
		elsif sizeRip != @sizeExpected 
			if @settings['debug']
				puts "Wrong filesize reported for track #{track} : #{sizeRip}"
				puts "Filesize should be : #{@sizeExpected}"
			end
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
			while index + 44 < @settings['cd'].fileSizeWav[track-1]
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
			@settings['log'].mismatch(track, @trial, @errors.keys, @settings['cd'].fileSizeWav[track-1], @settings['cd'].lengthSector[track-1]) # report for later position analysis
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
		@settings['log'].mismatch(track, @trial, @errors.keys, @settings['cd'].fileSizeWav[track-1], @settings['cd'].lengthSector[track-1]) 
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
			@settings['log'].mismatch(track, @trial, @errors.keys, @settings['cd'].fileSizeWav[track-1], @settings['cd'].lengthSector[track-1]) # report for later position analysis
			@settings['log'].add(_("%s chunk(s) didn't match %s times.\n") % [@errors.length, @reqMatchesErrors])
		end
	end
	
	def rip(track) # set cdparanoia command + parameters
		if @settings['image']
			@settings['log'].add(_("Starting to rip CD image, trial \#%s\n") % [@trial])
		else
			@settings['log'].add(_("Starting to rip track %s, trial \#%s\n") % [track, @trial])
		end
		command = "cdparanoia"
		if @settings['rippersettings'].size != 0 ; command += " #{@settings['rippersettings']}" end 
		if @settings['image'] # This means we're ripping the whole CD, set the command line parameters accordingly
			command += " [.0]-" #rip from sector 0 to the end of the disc
		else
			command += " [.#{@settings['cd'].startSector[track-1] - @settings['cd'].pregap[track-1]}]-" #start of track, prepend pregap
			if track != @settings['cd'].audiotracks #some drives don't work nicely with cdparanoia sector mode with last track.
				command += "[.#{@settings['cd'].lengthSector[track-1] - 1 + @settings['cd'].pregap[track-1]}]" #end of track, length + pregap
			end
		end
		if @settings['cd'].multipleDriveSupport ; command += " -d #{@settings['cdrom']}" end # the ported cdparanoia for MacOS misses the -d option, default drive will be used.
		command += " -O #{@settings['offset']}"
		command += " \"#{@settings['Out'].getTempFile(track, @trial)}\""
		unless @settings['verbose'] ; command += " 2>&1" end # hide the output of cdparanoia output
		puts command if @settings['debug']
		`#{command}` #Launch the cdparanoia command
	end
	
	def getDigest(track)
		digest = Digest::MD5.new()
		file = File.open(@settings['Out'].getTempFile(track, 1), 'r')
		index = 0
		while (index < @settings['cd'].fileSizeWav[track-1])
			digest << file.read(100000)
			index += 100000
		end
		file.close()
		@settings['log'].add(_("MD5 sum: %s\n\n") % [digest.hexdigest])
	end
end

class Encode < Monitor
	attr_reader :addTrack
	
	def initialize(settings)
		super()
		@settings = settings
		@progress = 0.0
		@threads = 0 # number of running threads
		@ready = true # is there a thread available?
		@waitingroom = Array.new # Track/codec waiting for a free thread.
		@busyTracks = Array.new # Tracks that are currently encoding
		@lasttrack = false
		@out = @settings['Out'] # create a shortcut

		# Set the charset environment variable to UTF-8. Oggenc needs this.
		# Perhaps others need it as well.
		ENV['CHARSET'] = "UTF-8" 
		@codecs = 0 # number of codecs
		['flac','vorbis','mp3','wav','other'].each do |codec|
			@codecs += 1 if @settings[codec]
		end
	end
	
	def addTrack(track)
		['flac', 'vorbis', 'mp3', 'wav', 'other'].each do |codec|
			if @settings[codec]
				@waitingroom << [track, codec]
				puts "Adding track #{track} (#{codec}) into the waitingroom.." if @settings['debug']
			end
		end
		
		if @settings['normalize'] == 'normalize' && @settings['gain'] == 'album' && @settings['tracksToRip'][-1] != track
			return false # normalize in album mode prevents encoding untill the last wav file is ripped
		elsif @settings['normalize'] == 'normalize' && @settings['gain'] == 'album' && @settings['tracksToRip'][-1] == track
			normalize() # last track has been ripped, so normalize and continue encoding
		elsif @settings['normalize'] == 'normalize' && @settings['gain'] == 'track'
			normalize(track)
		end
		
		if track == @settings['tracksToRip'][0] ; @settings['log'].encPerc(0.0) end # set it to 0% for the first track, so the gui shows it's started.
		if track == @settings['tracksToRip'][-1] ; @lasttrack = true end
		if @ready == true ; handleThreads() end
	end
	
	def handleThreads
		synchronize do #we don't want to mess up with shared variables, so synchronize
			while (@settings['maxThreads'] > @threads || @settings['maxThreads'] == 0) && @waitingroom.empty? == false
				puts "Inside handleThreads: maxthreads = #{@settings['maxThreads']}, threads = #{@threads}" if @settings['debug']	
				@threads += 1
				track, codec = @waitingroom.shift
				@busyTracks << track
				if @settings['maxThreads'] == 0
					encodeTrack(track, codec)
				else
					thread = Thread.new{ encodeTrack(track, codec) }
				end
			end
			if @settings['maxThreads'] > @threads || @settings['maxThreads'] == 0 ; @ready = true else @ready = false end
		end
	end
	
	def encodeTrack(track, codec)
		if codec == 'flac' ; doFlac(track)
		elsif codec == 'vorbis' ; doVorbis(track)
		elsif codec == 'mp3' ; doMp3(track)
		elsif codec == 'wav' ; doWav(track)
		elsif codec == 'other' ; doOther(track)
		end
		
		if @settings['debug']
			puts "busytracks = #{@busyTracks}, track = #{track}, codec = #{codec}"
		end
		
		# we don't want to mess up with shared variables, so synchronize
		synchronize do 
			# delete the first mention of this track,
			@busyTracks.delete_at(@busyTracks.index(track)) 
		
			#clean up wav's that are not needed anymore
			if !@waitingroom.flatten.include?(track) &&	
			!@busyTracks.include?(track) &&	File.exist?(@out.getTempFile(track, 1))
				File.delete(@out.getTempFile(track, 1))
			end
	
			@threads -= 1
			@progress += @settings['percentages'][track] / @codecs
			@settings['log'].encPerc(@progress)
		end

		if @waitingroom.empty? && @threads == 0 && @lasttrack == true
			finished()
		elsif @ready == false
			#if no threads where available for encoding, update the status
			handleThreads()
		end
	end
	
	def finished
		puts "Inside the finished function" if @settings['debug']
		@progress = 1.0 ; @settings['log'].encPerc(@progress)
		@settings['log'].summary(@settings['req_matches_all'], @settings['req_matches_errors'], @settings['max_tries'])
		if @settings['no_log'] ; @settings['log'].delLog end #Delete the logfile if no correction was needed if no_log is true
		@out.cleanTempDir()
		@settings['instance'].update("finished")
	end
	
	def normalize(track = false)
		if not installed('normalize')
			puts "WARNING: Normalize is not installed. Cannot normalize files"
			return false
		end
		
		if track == false #album mode
			command = "normalize -b \"#{@out.getTempDir()}/\"*.wav"
			`#{command}`
		else
			command = "normalize \"#{@out.getTempFile(track, 1)}\""
			`#{command}`
		end
	end
	
	def replaygain(filename, codec, track)
		if @settings['normalize'] == "replaygain"
			if @settings['gain'] == "album" && @settings['tracksToRip'][-1] == track ||@settings['gain']=="track"
				if codec == 'flac'
					if not installed('metaflac') ; puts "WARNING: Metaflac is not installed. Cannot replaygain files." ; return false end
					command = "metaflac --add-replay-gain \"#{if @settings['gain'] =="track" ; filename else File.dirname(filename) + "\"/*.flac" end}"
					`#{command}`
				elsif codec == 'vorbis'
					if not installed('vorbisgain') ; puts "WARNING: Vorbisgain is not installed. Cannot replaygain files." ; return false end
					command = "vorbisgain #{if @settings['gain'] =="track" ; "\"" + filename + "\"" else "-a \"" + File.dirname(filename) + "\"/*.ogg" end}"
					`#{command}`
				elsif codec == 'mp3'
					if not installed('mp3gain') ; puts "WARNING: Mp3gain is not installed. Cannot replaygain files." ; return false end
					command = "mp3gain -c #{if @settings['gain'] =="track" ; "-r \"" + filename + "\"" else "-a \"" + File.dirname(filename) + "\"/*.mp3" end}"
					`#{command}`
				elsif codec == 'wav'
					if not installed('wavegain') ; puts "WARNING: Wavegain is not installed. Cannot replaygain files." ; return false end
					command = "wavegain #{if @settings['gain'] =="track" ; "\"" + filename +"\"" else "-a \"" + File.dirname(filename) + "\"/*.wav" end}"
					`#{command}`
				end
			end
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
		command = @settings['other_settings'].dup

		command.gsub!('%n', sprintf("%02d", track))
		command.gsub!('%f', 'other')
		command.gsub!('%a', @out,artist)
		command.gsub!('%b', @out.album)
		command.gsub!('%g', @out.genre)
		command.gsub!('%y', @out.year)
		command.gsub!('%t', @out.getTrackname(track))
		command.gsub!('%va', @out.getVarArtist(track))
		command.gsub!('%i', @out.getTempFile(track, 1))
		command.gsub!('%o', @out.getFile(track, 'other'))
		checkCommand(command, track, 'other')
	end
	
	def flac(filename, track)
		tags = "--tag ALBUM=\"#{@out.album}\" "
		tags += "--tag DATE=\"#{@out.year}\" "
		tags += "--tag GENRE=\"#{@out.genre}\" "
		tags += "--tag DISCID=\"#{@settings['cd'].discId}\" "
		tags += "--tag DISCNUMBER=\"#{@settings['cd'].md.discNumber}\" " if @settings['cd'].md.discNumber
		
		 # Handle tags for single file images differently
		if @settings['image']
			tags += "--tag ARTIST=\"#{@out.artist}\" " #artist is always artist
			tags += "--tag TITLE=\"#{@out.album}\" " # title = album here
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

		command ="flac #{@settings['flacsettings']} -o \"#{filename}\" #{tags}"
		command += "\"#{@out.getTempFile(track, 1)}\""
		command += " 2>&1" unless @settings['verbose']

		checkCommand(command, track, 'flac')
	end
	
	def vorbis(filename, track)
		tags = "-c ALBUM=\"#{@out.album}\" "
		tags += "-c DATE=\"#{@out.year}\" "
		tags += "-c GENRE=\"#{@out.genre}\" "
		tags += "-c DISCID=\"#{@settings['cd'].discId}\" "
		tags += "-c DISCNUMBER=\"#{@settings['cd'].md.discNumber}\" " if @settings['cd'].md.discNumber

		 # Handle tags for single file images differently
		if @settings['image']
			tags += "-c ARTIST=\"#{@out.artist}\" "
			tags += "-c TITLE=\"#{@out.album}\""
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

		command = "oggenc -o \"#{filename}\" #{@settings['vorbissettings']} "
		command += "#{tags} \"#{@out.getTempFile(track, 1)}\" "
		command += " 2>&1" unless @settings['verbose']
	
		checkCommand(command, track, 'vorbis')
	end
	
	def mp3(filename, genre, track)
		tags = "--tl \"#{@out.album}\" "
		tags += "--ty \"#{@out.year}\" "
		tags += "--tg \"#{@out.genre}\" "
		tags += "--tv DISCID=\"#{@settings['cd'].discId}\" "
		tags += "--tv DISCNUMBER=\"#{@settings['cd'].md.discNumber}\" " if @settings['cd'].md.discNumber

		 # Handle tags for single file images differently
		if @settings['image']
			tags += "--ta \"#{@out.artist}\" "
			tags += "--tt \"#{@out.album}\" "
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

		#translate the UTF-8 tags to latin because of a lame bug.
		begin
			require 'iconv'
			tags = Iconv.conv("ISO-8859-1", "UTF-8", tags)		
		rescue
			puts "couldn't convert to ISO-8859-1 succesfully"
		end

		command = "lame #{@settings['mp3settings']} #{tags}"
		command += "\"#{@out.getTempFile(track, 1)}\" \"#{filename}\""
		command += " 2>&1" unless @settings['verbose']
	
		checkCommand(command, track, 'mp3')
	end
	
	def wav(filename, track)
		require 'fileutils'
		FileUtils.cp(@out.getTempFile(track, 1), filename)
	end
	
	def checkCommand(command, track, codec)
		exec = IO.popen("nice -n 6 " + command) #execute command
		exec.readlines() #get all the output
		
		if @settings['debug']
			puts "command = #{command}" 
			puts "Check exitstatus track #{track}, pid = #{exec.pid}"
		end
		
		if Process.waitpid2(exec.pid)[1].exitstatus != 0
			@settings['log'].add(_("WARNING: Encoding to %s exited with an error with track %s!\n") % [codec, track])
			@settings['log'].encodingErrors = true
		end
	end
end

class Rubyripper
attr_reader :settingsOk, :startRip, :postfixDir, :overwriteDir, :outputDir, :summary
	
	def initialize(settings, gui)
		@settings = settings.dup
		@directory = false
		@settings['log'] = false
		@settings['instance'] = gui
		@error = false
	end
	
	def settingsOk
		if not checkConfig() ; return @error end
		if not testDeps() ; return @error end
		@settings['cd'].md.saveChanges()
		@settings['Out'] = Output.new(@settings)
		return @settings['Out'].status
	end
	
	def startRip
		@settings['log'] = Gui_support.new(@settings)
		@outputDir = @settings['Out'].getDir()
		updateGui() # Give some info about the cdrom-player, the codecs, the ripper, cddb_info
		computePercentage() # Do some pre-work to get the progress updater working later on
		require 'digest/md5' # Needed for secure class, only have to load them ones here.
		@encoding = Encode.new(@settings) #Create an instance for encoding
		@ripping = SecureRip.new(@settings, @encoding) #create an instance for ripping
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
		
		temp = Disc.new(@settings['cdrom'], @settings['freedb'], @settings['instance'])
		if @settings['cd'].freedbString != temp.freedbString || @settings['cd'].playtime != temp.playtime
			@error = ["error", _("The Gui doesn't match inserted cd. Please press Scan Drive first.")]
 			return false
		end
		
		unless @settings['flac'] || @settings['vorbis'] || @settings['mp3'] || @settings['wav'] || @settings['other']
			@error = ["error", _("No codecs are selected!")]
			return false
 		end

		if @settings['other'] ; checkOtherSettings() end
 		
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
		
		@settings['log'].add(_("Codec(s) used:\n"))
		if @settings['flac']; @settings['log'].add(_("-flac \t-> %s (%s)\n") % [@settings['flacsettings'], `flac --version`.strip]) end
		if @settings['vorbis']; @settings['log'].add(_("-vorbis\t-> %s (%s)\n") % [@settings['vorbissettings'], `oggenc --version`.strip]) end
		if @settings['mp3']; @settings['log'].add(_("-mp3\t-> %s\n(%s\n") % [@settings['mp3settings'], `lame --version`.split("\n")[0]]) end
		if @settings['wav']; @settings['log'].add(_("-wav\n")) end
		if @settings['other'] ; @settings['log'].add(_("-other\t-> %s\n") % [@settings['othersettings']]) end
		@settings['log'].add(_("\nCDDB INFO\n"))
		@settings['log'].add(_("\nArtist\t= ") + @settings['cd'].md.artist)
		@settings['log'].add(_("\nAlbum\t= ") + @settings['cd'].md.album)
		@settings['log'].add(_("\nYear\t= ") + @settings['cd'].md.year)
		@settings['log'].add(_("\nGenre\t= ") + @settings['cd'].md.genre)
		@settings['log'].add(_("\nTracks\t= ") + @settings['cd'].audiotracks.to_s + "\n\n")
		@settings['cd'].audiotracks.times do |track|
			@settings['log'].add("#{sprintf("%02d", track + 1)} - #{@settings['cd'].md.tracklist[track]}\n")
		end
		@settings['log'].add(_("\nSTATUS\n\n"))
	end
	
	def computePercentage
		@settings['percentages'] = Hash.new() #progress for each track
		totalSectors = 0.0 # It can be that the user doesn't want to rip all tracks, so calculate it
		@settings['tracksToRip'].each{|track| totalSectors += @settings['cd'].lengthSector[track - 1]} #update totalSectors
		@settings['tracksToRip'].each{|track| @settings['percentages'][track] = @settings['cd'].lengthSector[track-1] / totalSectors}
	end
end
