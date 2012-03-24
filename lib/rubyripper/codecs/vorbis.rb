#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012  Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/codecs/main'

# This is the template for the Vorbis codec
# To add any new codec like "somecodec":
# * Add a file somecodec.rb into the same directory
# * Create a class "Somecodec" in it conform Vorbis
# * Add the codec to the preferences data
# * Add the option into the user interfaces
module Codecs
  class Vorbis   
    def tags
      {
        :artist => "-c ARTIST=",
        :album => "-c ALBUM=",
        :genre => "-c GENRE=",
        :year => "-c DATE=",
        :albumArtist => "-c \"ALBUM ARTIST\"=",
        :discNumber => "-c DISCNUMBER=",
        :encoder => "-c ENCODER=",
        :discId => "-c DISCID=",
        :trackname => "-c TITLE=",
        :tracknumber => "-c TRACKNUMBER=",
        :tracktotal => "-c TRACKTOTAL="
      }
    end
  
    def binary ; 'oggenc -o' ; end
    def extension ; 'ogg' ; end 
    def default; "-q 6" ; end
  
    # the sequence of the command
    def sequence ; [:binary, :output, :prefs, :tags, :input] ; end
  
    # %s will be replaced by the output file
    def replaygain(track)
      "vorbisgain %s"
    end
  
    # %s will be replaced by a File.join(output directory, *.extension)
    def replaygainAlbum
      "vorbisgain -a %s"
    end
  end
end