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

# This is the template for the Fdkaac (fraunhofer AAC) codec
module Codecs
  class Fraunhofer
    def tags
      {
        :artist => "--artist",
        :album => "--album",
        :genre => "--genre",
        :year => "--date",
        :albumArtist => "--album-artist",
        :discNumber => "--disk",
        :encoder => "--comment",
        :trackname => "--title",
        :tracknumber => "--track",
      }
    end
    
    def name ; 'fraunhofer' ; end
    def binary ; 'fdkaac' ; end
    def outputEncodingTag ; '-o' ; end
    def extension ; 'm4a' ; end
    def default; "-p 2 -m 5 -a 1" ; end
  
    # the sequence of the command
    def sequence ; [:binary, :prefs, :output, :tags, :input] ; end
  
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