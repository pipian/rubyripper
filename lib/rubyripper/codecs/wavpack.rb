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

# This is the template for the Wavpack codec
# To add any new codec like "somecodec":
# * Add a file somecodec.rb into the same directory
# * Create a class "Somecodec" in it conform Wavpack
# * Add the codec to the preferences data
# * Add the option into the user interfaces
# * Add the extension to filescheme class
module Codecs
  class Wavpack   
    def tags
      {
        :artist => "-w ARTIST=",
        :album => "-w ALBUM=",
        :genre => "-w GENRE=",
        :year => "-w DATE=",
        :albumArtist => "-w \"ALBUM ARTIST\"=",
        :discNumber => "-w DISCNUMBER=",
        :encoder => "-w ENCODER=",
        :discId => "-w DISCID=",
        :trackname => "-w TITLE=",
        :tracknumber => "-w TRACKNUMBER=",
        :tracktotal => "-w TRACKTOTAL=",
        :cuesheet => "-w CUESHEET="
      }
    end
  
    def binary ; 'wavpack' ; end
    def outputEncodingTag ; '-o' ; end  
    def extension ; 'wv' ; end 
    def default; "" ; end
  
    # the sequence of the command
    def sequence ; [:binary, :prefs, :tags, :input, :output] ; end
  
    # replaygain is not supported for wavpack
    def replaygain(track)
      ""
    end
  
    # replaygain is not supported for wavpack
    def replaygainAlbum
      ""
    end
  end
end