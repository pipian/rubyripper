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

# This is the template for the Opus codec
module Codecs
  class Opus   
    def tags
      {
        :artist => "--artist",
        :album => "--comment ALBUM=",
        :genre => "--comment GENRE=",
        :year => "--comment DATE=",
        :albumArtist => "--comment \"ALBUM ARTIST\"=",
        :discNumber => "--comment DISCNUMBER=",
        :encoder => "--comment ENCODER=",
        :discId => "--comment DISCID=",
        :trackname => "--title",
        :tracknumber => "--comment TRACKNUMBER=",
        :tracktotal => "--comment TRACKTOTAL="
      }
    end

    def name ; 'opus' ; end
    def binary ; 'opusenc' ; end
    def extension ; 'opus' ; end 
    def default; "--bitrate 160" ; end
  
    # the sequence of the command
    def sequence ; [:binary, :prefs, :tags, :input, :output] ; end
  
    # %s will be replaced by the output file
    def replaygain(track)
      puts "WARNING: No replaygain available for opus."
    end
  
    # %s will be replaced by a File.join(output directory, *.extension)
    def replaygainAlbum
      puts "WARNING: No replaygain available for opus."
    end
  end
end