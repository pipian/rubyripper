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

# This is the template for the Mp3 codec
module Codecs
  class Mp3   
    # if the tag ends with a equal sign no space is added
    # see http://www.id3.org/id3v2.3.0 for info about the TXXX Id3v2 frames
    def tags
      {
        :artist => "--ta",
        :album => "--tl",
        :genre => "--tv TCON=",
        :year => "--ty",
        :albumArtist => "--tv TPE2=",
        :discNumber => "--tv TPOS=",
        :encoder => "--tv TENC=",
        :discId => "--tc DISCID=",
        :trackname => "--tt",
        :tracknumberTotal => "--tn"
      }
    end

    def name ; 'mp3' ; end
    def binary ; 'lame' ; end
    def extension ; 'mp3' ; end 
    def default; "--preset fast standard" ; end
  
    # the sequence of the command
    def sequence ; [:binary, :prefs, :tags, :input, :output] ; end
  
    # %s will be replaced by the output file
    def replaygain(track)
      "mp3gain -c -r %s"
    end
  
    # %s will be replaced by a File.join(output directory, *.extension)
    def replaygainAlbum
      "mp3gain -c -a %s"
    end
  end
end