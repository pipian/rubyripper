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
  def initialize(out=nil, preferences=nil, int=nil, bool=nil, string=nil)
    @out = out ? out : $stdout
    @prefs = preferences
    @int = int ? int : CliGetInt.new(@out)
    @bool = bool ? bool : CliGetBool.new(@out)
    @string = string ? string : CliGetString.new(@out)
    @cd = Disc.new(@prefs)
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
  # read the disc contents
  def refreshDisc ; @cd.scan() ; end

  # show the contents of the audio disc
  def showDisc
    @out.puts ""

    if @cd.status != 'ok'
      @out.puts _("The disc is not ready: [%s]") % [@cd.status]
    else
      @out.puts _("AUDIO DISC FOUND")
      @out.puts _("Number of tracks: %s") % [@cd.audiotracks]
      @out.puts _("Total playtime: %s") % [@cd.playtime]
      @md = @cd.metadata
      showFreedb()
    end
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
    showDiscInfo()
    showTrackInfo()
    showFreedbOptions() unless @defaults
  end

  def showDiscInfo(edit=false)
    @out.puts "\nDISC INFO"
    @out.puts "1) " + _("Artist:") + " #{@md.artist}"
    @out.puts "2) " + _("Album:") + " #{@md.album}"
    @out.puts "3) " + _("Genre:") + " #{@md.genre}"
    @out.puts "4) " + _("Year:") + " #{@md.year}"
    @out.puts "5) " + _("Extra disc info:") + " #{@md.extraDiscInfo}"
    @out.puts "6) " + _("Marked as various disc? [%s]") % [@md.various? ? '*' : ' ']
    @out.puts "99) " + _("Finished editing disc info\n\n") if edit
    editDiscInfo() if edit
  end

  # Edit metadata at the disc level
  def editDiscInfo
    case answer = @int.get(_("Please enter the number you'd like to edit:"), 99)
      when 1 then @md.artist = @string.get(_("Artist:"), @md.artist)
      when 2 then @md.album = @string.get(_("Album:"), @md.album)
      when 3 then @md.genre = @string.get(_("Genre:"), @md.genre)
      when 4 then @md.year = @string.get(_("Year:"), @md.year)
      when 5 then @md.extraDiscInfo = @string.get(_("Extra disc info:"), @md.extraDiscInfo)
      when 6 then @md.various? ? @md.unsetVarArtist() : @md.setVarArtist()
      when 99 then showFreedbOptions() ; return true
    end
    editDiscInfo()
  end

  # Present the track info
  def showTrackInfo(edit=false)
    @out.puts _("\nTRACK INFO")
    (1..@cd.audiotracks).each do |tracknumber|
      trackname = @md.trackname(tracknumber)
      trackname = "#{@md.getVarArtist(tracknumber)} - #{trackname}" if @md.various?
      @out.puts "#{tracknumber}) #{trackname}"
    end

    @out.puts "" if edit
    @out.puts "99) " + _("Finished editing track info\n\n") if edit
    editTrackInfo if edit
  end

  # Edit metadata at the track level
  def editTrackInfo()
    case number = @int.get(_("Please enter the number you'd like to edit:"), 99)
    when number > 0 && number <= @cd.audiotracks
      @md.setTrackname(number, @string.get("Track #{number}:", @md.trackname(number)))
      raise "TODO: fix various artist input" if @md.various?
    when 99 then showFreedbOptions() ; return true
    end
    editTrackInfo()
  end

#        if not @md.varArtists.empty?
#          string = @string.get("Artist for Track #{answer} : ",  @md.varArtist(answer))
#          @md.setVarArtist(answer, string)
#        end

  # Present choice: edit metadata, start rip or break off
  def showFreedbOptions()
    @out.puts ""
    @out.puts _("What would you like to do?")
    @out.puts ""
    @out.puts _("1) Select the tracks to rip")
    @out.puts _("2) Edit the disc info")
    @out.puts _("3) Edit the track info")
    @out.puts _("4) Cancel the rip and eject the disc")
    @out.puts ""

    case answer = @int.get(_("Please enter the number of your choice: "), 1)
      when 1 then @status = "chooseTracks"
      when 2 then showDiscInfo(edit=true)
      when 3 then showTrackInfo(edit=true)
      when 4 then @status = "cancelRip"
      else showFreedbOptions()
    end
  end
end
