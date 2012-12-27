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

require 'rubyripper/disc/disc.rb'
require 'rubyripper/cli/cliGetAnswer'
require 'rubyripper/errors'
require 'rubyripper/preferences/main'

# Metadata class is responsible for showing and editing the metadata
class CliDisc
  include GetText
  GetText.bindtextdomain("rubyripper")
  
  attr_reader :cd, :error

  # setup the different objects
  def initialize(out=nil, int=nil, bool=nil, string=nil, prefs=nil)
    @out = out ? out : $stdout
    @prefs = prefs ? prefs : Preferences::Main.instance
    @int = int ? int : CliGetInt.new(@out)
    @bool = bool ? bool : CliGetBool.new(@out)
    @string = string ? string : CliGetString.new(@out)
    @cd = Disc.new()
  end

  # show the metadata to the screen
  def show
    refreshDisc()
    showDisc()
    showFreedb() if discReady?
  end

  # one of the options in the main menu
  def changeMetadata
    discReady? ? loopMainMenu() : showDiscNotReady()
  end

  # return all tracknames
  def tracks
    discReady? ? trackInfo() : Hash.new
  end

private
  def discReady? ; @cd.status == 'ok' ; end

  # read the disc contents
  def refreshDisc ; @cd.scan() ; end

  # show the contents of the audio disc
  def showDisc
    @out.puts ""

    if discReady?
      @out.puts _("AUDIO DISC FOUND")
      @out.puts _("Number of tracks: %s") % [@cd.audiotracks]
      @out.puts _("Total playtime: %s") % [@cd.playtime]
      @out.puts ""
      @md = @cd.metadata
    else
      @error = @cd.error
    end
  end

  # Present the disc info
  def showFreedb()
    showDiscInfo()
    showTrackInfo()
  end

  def showDiscInfo
    @out.puts "DISC INFO"
    discInfo().each_value{|value| @out.puts value}
    @out.puts ""
  end

  # build the discInfo
  def discInfo
    discInfo = Hash.new
    discInfo[1] = _("Artist:") + " #{@md.artist}"
    discInfo[2] = _("Album:") + " #{@md.album}"
    discInfo[3] = _("Genre:") + " #{@md.genre}"
    discInfo[4] = _("Year:") + " #{@md.year}"
    discInfo[5] = _("Extra disc info:") + " #{@md.extraDiscInfo}"
    discInfo[6] = _("Marked as various disc? [%s]") % [@md.various? ? '*' : ' ']
    return discInfo
  end

  def showTrackInfo
    @out.puts "TRACK INFO"
    trackInfo().each{|key, value| @out.puts "#{key}. #{value}"}
    @out.puts ""
  end

  # build the trackinfo
  def trackInfo
    trackInfo = Hash.new
    (1..@cd.audiotracks).each do |tracknumber|
      trackname = @md.trackname(tracknumber)
      trackname = "#{@md.getVarArtist(tracknumber)} - #{trackname}" if @md.various?
      trackInfo[tracknumber] = trackname
    end
    return trackInfo
  end

  # choose which the user wants to change
  def showMainMenu()
    @out.puts ""
    @out.puts "** " + _("EDIT METADATA") + " **"
    @out.puts ""
    @out.puts ' 1) ' + _('Edit the disc info')
    @out.puts ' 2) ' + _('Edit the track info')
    @out.puts '99) ' + _("Return to main menu")
    @out.puts ""
    @int.get("Please type the number of your choice", 99)
  end

  def loopMainMenu()
    case choice = showMainMenu()
      when 1 then loopSubMenuDisc()
      when 2 then loopSubMenuTracks()
      when 99 then @out.puts '' # return to start menu
    else
      noValidChoiceMessage(choice)
      loopMainMenu()
    end
  end

  def showSubMenuDisc()
    @out.puts ""
    @out.puts '*** ' + _("EDIT DISC INFO") + ' ***'
    @out.puts ""
    discInfo().each{|key, value| @out.puts "%2d) #{value}" % key}
    @out.puts "99) " + _("Back to metadata menu")
    @out.puts ""
    @int.get("Please type the number of the data you wish to change", 99)
  end

  def loopSubMenuDisc
    case choice = showSubMenuDisc()
      when 1 then @md.artist = @string.get(_("Artist:"), @md.artist)
      when 2 then @md.album = @string.get(_("Album:"), @md.album)
      when 3 then @md.genre = @string.get(_("Genre:"), @md.genre)
      when 4 then @md.year = @string.get(_("Year:"), @md.year)
      when 5 then @md.extraDiscInfo = @string.get(_("Extra disc info:"), @md.extraDiscInfo)
      when 6 then @md.various? ? @md.unmarkVarArtist() : @md.markVarArtist()
      when 99 then loopMainMenu()
    else
      noValidChoiceMessage(choice)
    end
    loopSubMenuDisc unless choice == 99
  end

  def noValidChoiceMessage(choice)
    @out.puts _("Number %s is not a valid choice, try again.") % [choice]
  end

  def showSubMenuTracks
    @out.puts ""
    @out.puts '*** ' + _('EDIT TRACK INFO') + ' ***'
    @out.puts ""
    trackInfo().each{|key, value| @out.puts "%2d) #{value}" % key}
    @out.puts "99) " + _("Back to metadata menu")
    @out.puts ""
    @int.get("Please type the number of the data you wish to change", 99)
  end

  def loopSubMenuTracks()
    number = showSubMenuTracks()
    if number > 0 && number <= @cd.audiotracks
      if @md.various?
        @md.setVarArtist(number,
          @string.get(_("Artist:"), @md.getVarArtist(number)))
      end
      @md.setTrackname(number, @string.get(_("Track name:"),
        @md.trackname(number)))
    elsif number == 99 ; loopMainMenu()
    else
      noValidChoiceMessage(number)
    end
    loopSubMenuTracks unless number == 99
  end
end

  # return the disc object
  # def disc ; return @disc ; end
  # return status when finished
  #def status ; return @status ; end
  # return any problems reported
  #def error ; return @error ; end

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


#        if not @md.varArtists.empty?
#          string = @string.get("Artist for Track #{answer} : ",  @md.varArtist(answer))
#          @md.setVarArtist(answer, string)
#        end


