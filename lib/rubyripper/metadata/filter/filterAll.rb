#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/preferences/main'

module Metadata
  class FilterAll
    
    def initialize(data, prefs=nil)
      @md = data
      @prefs = prefs ? prefs : Preferences::Main.instance
    end
    
    def filter(item)
      item.gsub!('`', "'") # remove backquotes

      # replace any underscores with spaces, some freedb info got
      # underscores instead of spaces
      item.gsub!('_', ' ') unless @prefs.noSpaces

      if item.respond_to?(:encoding)
        # prepare for byte substitutions
        enc = item.encoding
        item.force_encoding("ASCII-8BIT")
      end

      # replace utf-8 single quotes with latin single quote
      item.gsub!(/\342\200\230|\342\200\231/, "'")

      # replace utf-8 double quotes with latin double quote
      item.gsub!(/\342\200\234|\342\200\235/, '"')

      if item.respond_to?(:encoding)
        # restore the old encoding
        item.force_encoding(enc)
      end
      
      item.strip!
      item
    end
    
    private
    
    # if the method is not found try to look it up in the data object
    def method_missing(name, *args)
      item = @md.send(name, *args)
      if item.class == String
        filter(item)
      else
        item
      end
    end
  end
end
