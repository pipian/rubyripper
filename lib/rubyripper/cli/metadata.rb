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

require 'rubyripper/quickScanDisc.rb'

# Metadata class is responsible for showing and editing the metadata

class CliMetadata
attr_reader :getStatus, :getError

	def initialize(settings, defaults)
		@settings = settings
		@error = ''
		@defaults = defaults
		@status = false
		getDiscInfo()
	end

	# return status when finished
	def getStatus
		return @status
	end

	# return error
	def getError
		return @error
	end

	# Analyze the TOC of disc in drive
	def getDiscInfo
		@settings['cd'] = QuickScanDisc.new(@settings, self)
		
		# When a disc is found
		if @settings['cd'].audiotracks != 0
			puts _("Audio-disc found, number of tracks : %s, total playlength \
: %s") % [@settings['cd'].audiotracks, @settings['cd'].playtime]			
			# When freedb is enabled 
			if @settings['freedb']
				puts _("Fetching freedb info...")
				handleFreedb()
			else
				showFreedb()
			end
		# When no disc is found
		else 
			@error = @settings['cd'].error
		end
	end

	# Fetch the cddb info, if choice is true, multiple discs were available
	def handleFreedb(choice = false)
		status = @settings['cd'].getFreedbInfo(choice)
		
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
			puts "Unknown error with Freedb class.", status
		end
	end

	# Present the freedb choices to the user
	def chooseFreedb(choices)
		puts _("Freedb reported multiple possibilities.")
		if @defaults == true
			puts _("The first freedb option is automatically selected (no questions allowed)")
			handleFreedb(0)
		else
			choices.each_index{|index| puts "#{index + 1}) #{choices[index]}"}
			choice = getAnswer(_("Please type the number of the one you prefer? : "), "number", 1)
			handleFreedb(choice - 1)
		end
	end

	# Present the disc info
	def showFreedb()
		puts ""
		puts _("FREEDB INFO\n\n")
		puts _("DISC INFO")
		print _("Artist:") ; print " #{@settings['cd'].freedb.artist}\n"
		print _("Album:") ; print " #{@settings['cd'].freedb.album}\n"
		print _("Genre:") ; print " #{@settings['cd'].freedb.genre}\n"
		print _("Year:") ; print " #{@settings['cd'].freedb.year}\n"
		puts ""
		puts _("TRACK INFO")
		
		showTracks()
		if @defaults
			@status = "default"
		else
			showFreedbOptions()
		end
	end

	# Present the track info
	def showTracks()
		@settings['cd'].audiotracks.times do |index|
			trackname = @settings['cd'].freedb.tracklist[index]
			if not @settings['cd'].freedb.varArtists.empty?
				trackname = "#{@settings['cd'].freedb.varArtists[index]} - #{trackname}"
			end

			puts "#{index +1 }) #{trackname}"
		end
	end

	# Present choice: edit metadata, start rip or break off
	def showFreedbOptions()
		puts ""
		puts _("What would you like to do?")
		puts ""
		puts _("1) Select the tracks to rip")
		puts _("2) Edit the disc info")
		puts _("3) Edit the track info")
		puts _("4) Cancel the rip and eject the disc")
		puts ""

		answer = getAnswer(_("Please enter the number of your choice: "), "number", 1)
		if answer == 1 ; @status = "chooseTracks"
		elsif answer == 2 ; editDiscInfo()
		elsif answer == 3 ; editTrackInfo()
		else @status = "cancelRip"
		end
	end

	# Edit metadata at the disc level
	def editDiscInfo()
		puts "1) " + _("Artist:") + " #{@settings['cd'].freedb.artist}"
		puts "2) " + _("Album:") + " #{@settings['cd'].freedb.album}"
		puts "3) " + _("Genre:") + " #{@settings['cd'].freedb.genre}"
		puts "4) " + _("Year:") + " #{@settings['cd'].freedb.year}"
		
		if @settings['cd'].freedb.varArtists.empty?
			puts "5) " + _("Mark disc as various artist")
		else
			puts "5) " + _("Mark disc as single artist")
		end

		puts "99) " + _("Finished editing disc info\n\n")
		
		while true
			answer = getAnswer(_("Please enter the number you'd like to edit: "), "number", 99)
			if answer == 1 ; @settings['cd'].freedb.artist = getAnswer(_("Artist : "), "open", @settings['cd'].freedb.artist)
			elsif answer == 2 ; @settings['cd'].freedb.album = getAnswer(_("Album : "), "open", @settings['cd'].freedb.album)
			elsif answer == 3 ; @settings['cd'].freedb.genre = getAnswer(_("Genre : "), "open", @settings['cd'].freedb.genre)
			elsif answer == 4 ; @settings['cd'].freedb.year = getAnswer(_("Year : "), "open", @settings['cd'].freedb.year)
			elsif answer == 5 ; if @settings['cd'].freedb.varArtists.empty? ; setVarArtist() else unsetVarArtist() end
			elsif answer == 99 ; break
			end
		end

		showFreedb()
	end

	# Mark the disc as various artist
	def setVarArtist
		@settings['cd'].audiotracks.times do |time|
			if @settings['cd'].freedb.varArtists[time] == nil
				@settings['cd'].freedb.varArtists[time] = _('Unknown')
			end
		end
	end
	
	# Unmark the disc as various artist
	def unsetVarArtist
		@settings['cd'].freedb.undoVarArtist()
	end

	# Edit metadata at the track level
	def editTrackInfo()
		showTracks()
		puts ""
		puts "99) " + _("Finished editing track info\n\n")

		while true
			answer = getAnswer(_("Please enter the number you'd like to edit: "), "number", 99)
		
			if answer == 99 ; break
			elsif (answer.to_i > 0 && answer.to_i <= @settings['cd'].audiotracks)
				@settings['cd'].freedb.tracklist[answer - 1] = getAnswer("Track #{answer} : ", "open", @settings['cd'].freedb.tracklist[answer - 1])
				if not @settings['cd'].freedb.varArtists.empty?
					@settings['cd'].freedb.varArtists[answer - 1] = getAnswer("Artist for Track #{answer} : ", "open", @settings['cd'].freedb.varArtists[answer - 1])
				end
			else
				puts _("This is not a valid number. Try again")
			end
		end

		showFreedb()
	end
end
