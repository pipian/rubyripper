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

require 'rubyripper/datamodel/track'

# This class stores all disc data
module Datamodel
  class Disc
    def initialize
      @tracks = Hash.new()
    end

    def getTrack(tracknumber)
      @tracks[tracknumber]
    end

    def addTrack(number, startSector, lengthSector)
      @tracks[number] = Track.new()
      @tracks[number].number = number
      @tracks[number].startSector = startSector
      @tracks[number].lengthSector = lengthSector
    end
  end
end