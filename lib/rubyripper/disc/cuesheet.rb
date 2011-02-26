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

# The Cuesheet class is there to provide a Cuesheet. It is
# called from the AccurateScanDisc class after the toc scanning has
# finished. There are several variants for building a cuesheet.
# It at least needs a reference to all files. Single file is
# the most simple, since the prepend / append discussion isn't
# relevant here.
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
