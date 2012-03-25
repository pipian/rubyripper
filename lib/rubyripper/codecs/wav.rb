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

# This is the template for the Wav codec
module Codecs
  class Wav   
    def tags ; Hash.new ; end
    def name ; 'wav' ; end
    def binary ; 'cp' ; end
    def extension ; 'wav' ; end 
  
    # the sequence of the command
    def sequence ; [:binary, :input, :output] ; end
  
    # %s will be replaced by the output file
    def replaygain(track)
      "wavegain %s"
    end
  
    # %s will be replaced by a File.join(output directory, *.extension)
    def replaygainAlbum
      "wavegain -a %s"
    end
  end
end