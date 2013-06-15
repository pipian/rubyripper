#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2013  Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/modules/audioCalculations'
require 'rubyripper/datamodel/track'

class RipStrategy
  include AudioCalculations

  # disc is the datamodel object
  def initialize(disc, prefs=nil)
    @disc = disc
    @prefs = prefs ? prefs : Preferences::Main.instance()
  end

  def getTrack(number)
    @disc.getTrack(number)
  end

  def isHiddenTrackAvailable
    if @prefs.ripHiddenAudio
      minimumSectors = @prefs.minLengthHiddenTrack * FRAMES_A_SECOND
      return @disc.getTrack(1).startSector >= minimumSectors
    else
      return false
    end
  end

  def getHiddenTrack
    if isHiddenTrackAvailable
      hiddenTrack = Datamodel::Track.new()
      hiddenTrack.startSector = 0
      hiddenTrack.lengthSector = @disc.getTrack(1).startSector
      return hiddenTrack
    else
      raise "Only use this function if a hidden track is available: use isHiddenTrackAvailable() first."
    end
  end

  def getCdParanoiaSectorsToRipString(tracknumber)
    return "#{@disc.getTrack(tracknumber).startSector}-#{@disc.getTrack(tracknumber).lengthSector}"
  end
end