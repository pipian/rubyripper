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

# This is the template for the Nero AAC codec
module Codecs
  class Nero   
    def tags
      {
        :artist => "-meta:artist=",
        :album => "-meta:album=",
        :genre => "-meta:genre=",
        :year => "-meta:year=",
        :albumArtist => "-meta-user:\"ALBUM ARTIST\"=",
        :discNumber => "-meta:disc=",
        :encoder => "-meta-user:ENCODER=",
        :discId => "-meta-user:DISCID=",
        :trackname => "-meta:title=",
        :tracknumber => "-meta:track=",
        :tracktotal => "-meta:totaltracks="
      }
    end
    
    def inputEncodingTag ; '-if'; end
    def outputEncodingTag ; '-of'; end

    def name ; 'nero' ; end
    def binary ; 'neroAacEnc' ; end
    def extension ; 'aac' ; end 
    def default; "-q 0.5" ; end
  
    # the sequence of the command
    def sequence ; [:binary, :prefs, :input, :output] ; end
      
    def tagBinary ; 'neroAacTag' ; end
    def sequenceTags; [:binary, :input, :tags] ; end
  
    # %s will be replaced by the output file
    def replaygain(track)
      "aacgain -c -r %s"
    end
  
    # %s will be replaced by a File.join(output directory, *.extension)
    def replaygainAlbum
      "aacgain -c -a %s"
    end
  end
end
