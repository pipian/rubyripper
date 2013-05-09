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

      # replace utf-8 single quotes with latin single quote
      # see also http://www.utf8-chartable.de/unicode-utf8-table.pl
      item.gsub!(/\u{02018}|\u{02019}/, "'")

      # replace utf-8 double quotes with latin double quote
      item.gsub!(/\u{0201c}|\u{0201d}/, '"')

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
