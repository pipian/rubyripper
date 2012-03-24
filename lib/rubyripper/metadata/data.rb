#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012 Bouke Woudstra (boukewoudstra@gmail.com)
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

# Store all metadata
module Metadata
  class Data
    include GetText
    GetText.bindtextdomain("rubyripper")
    def self._(txt) ; GetText._(txt) ; end 
    
    attr_accessor :artist, :album, :genre, :year, :tracklist, :varArtist,
      :extraDiscInfo, :discid, :discNumber

    DEFAULT_METADATA = _('Unknown')
    DEFAULT_TRACKNAME = _('Track %s')
    DEFAULT_YEAR = '0'

    def initialize
      @artist = DEFAULT_METADATA
      @album = DEFAULT_METADATA
      @genre = DEFAULT_METADATA
      @year = DEFAULT_YEAR
      @extraDiscInfo = ''
      @discid = ''
      @tracklist = Hash.new
      @varArtist = Hash.new
    end

    # get the trackname for a given tracknumber
    def trackname(number)
      @tracklist[number] ? @tracklist[number] : DEFAULT_TRACKNAME % number
    end

    # set the trackname for a given tracknumber
    def setTrackname(number, name)
      @tracklist[number] = name
    end

    # get the artist for a given tracknumber
    def getVarArtist(number)
      @varArtist[number] ? @varArtist[number] : DEFAULT_METADATA
    end

    # set the artist for a given tracknumber
    def setVarArtist(number,value)
      @varArtist[number] = value
    end

    # mark the disc various
    def markVarArtist
      @tracklist.each_key{|key| @varArtist[key] = DEFAULT_METADATA} unless various?
    end

    # unmark the disc as various
    def unmarkVarArtist
      if various?
        @varArtist.each_key do |key|
          if @varArtist[key] != DEFAULT_METADATA
            @tracklist[key] = "#{@varArtist[key]} #{@tracklist[key]}"
          end
        end
        @varArtist = Hash.new
      end
    end
    
    def trackArtist(number)
      if number == nil || !various?
        artist
      else
        getVarArtist(number)
      end
    end
  
    def various? ; @varArtist.size > 0 ; end
  end
end
