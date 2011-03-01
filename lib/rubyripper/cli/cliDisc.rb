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

require 'rubyripper/disc'
require 'rubyripper/cli/cliGetAnswer'

# Metadata class is responsible for showing and editing the metadata
class CliDisc

  # setup the different objects
  def initialize(preferences, int=nil, bool=nil, string=nil)
    @prefs = preferences
    @int = int ? int : CliGetInt.new
    @bool = bool ? bool : CliGetBool.new
    @string = string ? string : CliGetString.new
    @disc = Disc.new(@prefs)
  end

  # show the metadata to the screen
  def show
    refreshDisc()
    showDisc()
  end

  # return the disc object
  # def disc ; return @disc ; end
  # return status when finished
  #def status ; return @status ; end
  # return any problems reported
  #def error ; return @error ; end

private
  # return the metadata object
  def md ; @disc.metadata ; end

  # read the disc contents
  def refreshDisc ; @disc.scan() ; end

  # show the contents of the audio disc
  def showDisc
    puts ""

    if @disc.status != 'ok'
      puts _("The disc is not ready: [%s]") % [@disc.status]
    else
      puts _("AUDIO DISC FOUND")
      puts _("Number of tracks: %s") % [@disc.audiotracks]
      puts _("Total playtime: %s") % [@disc.playtime]
    end
  end

  # Analyze the TOC of disc in drive
  def getDiscInfo
    @cd = @disc.scan
    @md = @disc.md

    # When a disc is found
    showFreedb()
    # When freedb is enabled
    #if @settings['freedb']
    #puts _("Fetching freedb info...")
    # handleFreedb()
    #else
    #showFreedb()
    #end
    #When no disc is found
    #else
    #puts "ERROR: No disc found."
    #exit()
    #end
  end

	# Fetch the cddb info, if choice is true, multiple discs were available
	#def handleFreedb(choice = false)
	#	status = @cd.getFreedbInfo(choice)
	#
	#	if status == true #success
	#		showFreedb()
	#	elsif status[0] == "choices"
	#		chooseFreedb(status[1])
	#	elsif status[0] == "noMatches"
	#		update("error", status[1]) # display the warning, but continue anyway
	#		showFreedb()
	#	elsif status[0] == "networkDown" || status[0] == "unknownReturnCode" || status[0] == "NoAudioDisc"
	#		update("error", status[1])
	#	else
	#		puts "Unknown error with Freedb class.", status
	#	end
	#end

	# Present the freedb choices to the user
	#def chooseFreedb(choices)
	#	puts _("Freedb reported multiple possibilities.")
	#	if @defaults == true
	#		puts _("The first freedb option is automatically selected (no questions allowed)")
	#		handleFreedb(0)
	#	else
	#		choices.each_index{|index| puts "#{index + 1}) #{choices[index]}"}
	#		choice = getAnswer(_("Please type the number of the one you prefer? : "), "number", 1)
	#		handleFreedb(choice - 1)
	#	end
	#end

	# Present the disc info
	def showFreedb()
		puts ""
		puts _("FREEDB INFO\n\n")
		puts _("DISC INFO")
		print _("Artist:") ; print " #{@md.artist}\n"
		print _("Album:") ; print " #{@md.album}\n"
		print _("Genre:") ; print " #{@md.genre}\n"
		print _("Year:") ; print " #{@md.year}\n"
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
		@cd.getInfo('audiotracks').times do |index|
			trackname = @md.trackname(index + 1)
			if @md.varArtists
				trackname = "#{@md.varArtist(index+1)} - #{trackname}"
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

		answer = ''
		while answer != 1 && answer != 4
			answer = @int.get(_("Please enter the number of your choice: "), 1)
			if answer == 1 ; @status = "chooseTracks"
			elsif answer == 2 ; editDiscInfo()
			elsif answer == 3 ; editTrackInfo()
			elsif answer == 4 ; @status = "cancelRip"
			end
		end
	end

	# Edit metadata at the disc level
	def editDiscInfo()
		puts "1) " + _("Artist:") + " #{@md.artist}"
		puts "2) " + _("Album:") + " #{@md.album}"
		puts "3) " + _("Genre:") + " #{@md.genre}"
		puts "4) " + _("Year:") + " #{@md.year}"

		if @md.varArtists.empty?
			puts "5) " + _("Mark disc as various artist")
		else
			puts "5) " + _("Mark disc as single artist")
		end

		puts "99) " + _("Finished editing disc info\n\n")

		answer = ''
		while answer != 99
			answer = @int.get(_("Please enter the number you'd like to edit: "), 99)
			if answer == 1 ; @md.artist = @string.get(_("Artist : "), @md.artist)
			elsif answer == 2 ; @md.album = @string.get(_("Album : "), @md.album)
			elsif answer == 3 ; @md.genre = @string.get(_("Genre : "), @md.genre)
			elsif answer == 4 ; @md.year = @string.get(_("Year : "), @md.year)
			elsif answer == 5 ; if @md.varArtists.empty? ; setVarArtist() else unsetVarArtist() end
			end
		end

		showFreedb()
	end

	# Mark the disc as various artist
	def setVarArtist
		@cd.audiotracks.times do |time|
			if @md.varArtists[time] == nil
				@md.varArtists[time] = _('Unknown')
			end
		end
	end

	# Unmark the disc as various artist
	def unsetVarArtist
		@md.undoVarArtist()
	end

	# Edit metadata at the track level
	def editTrackInfo()
		showTracks()
		puts ""
		puts "99) " + _("Finished editing track info\n\n")

		while true
			answer = @int.get(_("Please enter the number you'd like to edit: "), 99)

			if answer == 99 ; break
			elsif (answer.to_i > 0 && answer.to_i <= @cd.getInfo('audiotracks'))
				string = @string.get("Track #{answer} : ", @md.trackname(answer))
				@md.setTrackname(answer, string)
				if not @md.varArtists.empty?
					string = @string.get("Artist for Track #{answer} : ",  @md.varArtist(answer))
					@md.setVarArtist(answer, string)
				end
			else
				puts _("This is not a valid number. Try again")
			end
		end

		showFreedb()
	end
end
