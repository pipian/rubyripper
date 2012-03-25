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

# This is the template for the Flac codec
module Codecs
  class Flac   
    def tags
      {
        :artist => "--tag ARTIST=",
        :album => "--tag ALBUM=",
        :genre => "--tag GENRE=",
        :year => "--tag DATE=",
        :albumArtist => "--tag \"ALBUM ARTIST\"=",
        :discNumber => "--tag DISCNUMBER=",
        :encoder => "--tag ENCODER=",
        :discId => "--tag DISCID=",
        :trackname => "--tag TITLE=",
        :tracknumber => "--tag TRACKNUMBER=",
        :tracktotal => "--tag TRACKTOTAL=",
        :cuesheet => "--cuesheet="
      }
    end

    def name ; 'flac' ; end
    def binary ; 'flac' ; end
    def outputEncodingTag ; '-o' ; end  
    def extension ; 'flac' ; end 
    def default; "--best" ; end
  
    # the sequence of the command
    def sequence ; [:binary, :output, :prefs, :tags, :input] ; end
  
    # %s will be replaced by the output file
    def replaygain(track)
      "metaflac --add-replay-gain %s"
    end
  
    # %s will be replaced by a File.join(output directory, *.extension)
    def replaygainAlbum
      "metaflac --add-replay-gain %s"
    end
  end
end
