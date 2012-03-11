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

require 'rubyripper/cli/cliGetAnswer'
require 'rubyripper/cli/cliDisc'
require 'rubyripper/preferences/main'

# Tracklist class is responsible for showing and editing the metadata
class CliTracklist
  include GetText
  GetText.bindtextdomain("rubyripper")

  def initialize(disc, out=nil, int=nil, prefs=nil)
    @out = out ? out : $stdout
    @int = int ? int : CliGetInt.new(@out)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @cliDisc = disc
  end

  # return the selection, if not set return all tracks
  def selection
    @selection ||= @cliDisc.tracks.keys
  end

  # go into the track selection menu
  def show
    if @prefs.image
      @out.puts _('It\'s not possible to select tracks for image rips')
      @out.puts _('Please change your rip preferences first')
    else
      selection()
      loopTrackMenu()
    end
  end

private
  # show the tracks
  def showTrackMenu
    @out.puts ''
    @out.puts '** ' + _("TRACK SELECTION") + ' **'
    @out.puts ''
    @cliDisc.tracks.each do |number, name|
      @out.puts "%2d) %s %s" % [number, short(name), showBool(number)]
    end
    @out.puts ''
    @out.puts '88) ' + _('To toggle all tracks on/off')
    @out.puts "99) " + _("Back to main menu")
    @out.puts ''
    @int.get("Please type the number you wish to change", 99)
  end

  # show 30 characters and fill it out
  def short(name)
    @maxLength ||= 30
    if name.length >= @maxLength
      name[0..(@maxLength-1)]
    else
      name + ' ' * (@maxLength -name.length)
    end
  end

  def showBool(number)
    @selection.include?(number) ? '[*]' : '[ ]'
  end

  def noValidChoiceMessage(choice)
    @out.puts _("Number %s is not a valid choice, try again.") % [choice]
  end

  # add missing track, remove existing track
  def toggleTrack(track)
    if @selection.include?(track)
      @selection.delete_if{|item| item == track}
    else
      @selection << track
      @selection.sort!
    end
  end

  # loop this menu untill user chooses 99
  def loopTrackMenu
    number = showTrackMenu()
    if number > 0 && number <= @cliDisc.tracks.size
      toggleTrack(number)
    elsif number == 88
      @selection.empty? ? @selection = @cliDisc.tracks.keys : @selection.clear()
    elsif number == 99
      @out.puts ''
    else noValidChoiceMessage(number)
    end
    loopTrackMenu unless number == 99
  end
end
