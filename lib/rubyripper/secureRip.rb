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

# The SecureRip class is mainly responsible for:
# * Managing cdparanoia to fetch the files
# * Comparing the fetched files
# * Repairing the files if necessary

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
		elsif @settings['offset'] != 0 && (track == "image" || track == @settings['cd'].audiotracks)
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
