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

require 'tmpdir'

# The scanDiscCdrdao class helps detecting all special audio-cd
# features as hidden tracks, pregaps, etcetera. It does so by 
# analyzing the output of cdrdao's TOC output. The class is only
# opened when the user has the cuesheet enabled. This is so because
# there is not much of an advantage of detecting pregaps when
# they're just added to the file anyway. You want to detect
# the gaps so you can reproduce the original disc exactly. The
# cuesheet is necessary to store the gap info.
# The scanning will take about 1 - 2 minutes.

class ScanDiscCdrdao
	
	# settings = Hash with all settings
	# testRead = sample scans for cdrdao for unit testing purposes
	def initialize(settings, testRead = false)
		@settings = settings
		@testRead = testRead
		@cdrom = @settings['cdrom']
		checkArguments()

		@status = _('ok')
		@scan = Hash.new
		@buildLog = Array.new

		@scan['preEmphasis'] = Array.new
		@scan['dataTracks'] = Array.new
		@scan['preGap'] = Hash.new
		@scan['trackNames'] = Hash.new
		@scan['varArtists'] = Hash.new

		@output = @testRead || getOutput()		

		if isValidQuery()
			parseQuery()
			makeLog()
		end
	end

	# return the logfile
	def getLog ; return @buildLog ; end

	# return the status, _('ok') is good
	def status ; return @status ; end
	
	# return the scan variable
	def getInfo(key=false)
		if key == false
			return @scan
		else
			if @scan.key?(key)
				return @scan[key]
			else
				return false
			end
		end
	end

private

	# check the parameters
	def checkArguments
		unless @settings.class == Hash
			raise ArgumentError, "settings parameter must be a Hash"
		end

		unless @testRead == false || @testRead.class == String
			raise ArgumentError, "testRead parameter must be a string"
		end
	end
	
	# get all the cdrdao info
	def getOutput
		# find a temporary location
		@file = File.join(Dir.tmpdir, "temp_#{File.basename(@cdrom)}.toc")
		File.delete(@file) if File.exist?(@file)
		
		# build the command
		command = "cdrdao read-toc --device #{@cdrom} \"#{@file}\""
		command += " 2>&1" unless @settings['verbose']
		puts "cdrdao scan is started:" if @settings['debug']		
		puts command if @settings['debug']

		# fire the command
		`#{command}`
		if $?.succes? ; return File.read(@file) else return String.new end
	end

	# check if the output is valid
	def isValidQuery
		if @output == ''
			@status = _('ERROR: Cdrdao exited unexpectedly.')
		elsif @output.include?('ERROR: Unit not ready, giving up.')
			@status = _("ERROR: No disc found")
		elsif @output.include?('Usage: cdrdao')
			@status = _('ERROR: %s doesn\'t recognize the parameters.') %['Cdrdao']
		elsif @output.include?('ERROR: Cannot setup device')
			@status = _('ERROR: Not a valid cdrom drive')
		end

		return @status == _('ok')
	end

	# minutes:seconds:sectors to sectors
	def toSectors(time)
		count = 0
		minutes, seconds, sectors = time.split(':')
		count += sectors.to_i
		count += (seconds.to_i * 75)
		count += (minutes.to_i * 60 * 75)
		return count
	end

	# read the file of cdrdao into the scan Hash
	def parseQuery
		track = 0
		@output.each_line do |line|
			if line[0..1] == 'CD' && !@scan.key?('discType')
				@scan['discType'] = line.strip()
			elsif track == 0 && line =~ /TITLE /
				@scan['artist'], @scan['album'] = $'.strip()[1..-2].split(/\s\s+/)
			elsif track == 0 && line =~ /SILENCE /
				@scan['silence'] = toSectors($'.strip)	
			elsif line =~ /Track/
				track += 1
			elsif line =~ /TRACK DATA/
				@scan['dataTracks'] << track
			elsif line[0..11] == 'PRE_EMPHASIS'
				@scan['preEmphasis'] << track
			elsif line =~ /START /
				@scan['preGap'][track] = toSectors($'.strip)
			elsif line =~ /TITLE /
				@scan['trackNames'][track] = $'.strip()[1..-2] #exclude quotes
			elsif track > 0 && line =~ /PERFORMER /
				if $'.strip().length > 2
					@scan['varArtists'][track] = $'[1..-2] #exclude quotes
				end 
			end
		end
		@scan['tracks'] = track
	end

	# report all special cases
	def makeLog
		if @scan['preEmphasis'].empty? && @scan['preGap'].empty? && !@scan.key?('silence')
			@buildLog << _("No pregaps, silences or pre-emphasis detected\n")
			return true
		end

		@buildLog << _("Silence detected for disc : %s sectors\n") % [@scan['silence']] 

		(1..@scan['tracks']).each do |track|
			# pregap detected?
			@buildLog << _("Pregap detected for track %s : %s sectors\n") %
[track, @scan['preGap'][track]] if @scan['preGap'].key?(track)
			# pre emphasis detected?
			@buildLog << ("Pre_emphasis detected for track %s\n") %
[track] if @scan['preEmphasis'].include?(track)
			# is the track marked as data track?
			@buildLog << _("Track %s is marked as a DATA track\n") %
[track] if @scan['dataTracks'].include?(track)
		end

		#set an extra whiteline before starting to rip
		@buildLog << "\n"
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

