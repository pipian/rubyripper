#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010  Bouke Woudstra (boukewoudstra@gmail.com)
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
require 'rubyripper/system/fileAndDir'

# This class will try to save the Rubyripper config file
module Preferences
  class Save
    def initialize(fileAndDir=nil, prefs=nil)
      @prefs = prefs ? prefs : Preferences::Main.instance
      @filename = @prefs.filename()
      @data = @prefs.data()
      @file = fileAndDir ? fileAndDir : FileAndDir.instance
      save()
      @data.setActiveCodecs()
    end

    private

    # get all instance variables and call their contents
    # for example if data.instance_variables returns [:@artist, :@album]
    # this function will save artist=#{@data.artist} and album=#{@data.album}
    def save
      content = String.new
      @data.instance_variables.each do |var|
        next if var == :@codecs
        content << "#{var[1..-1]}=#{@data.send(var[1..-1].to_sym)}\n"
      end

      @file.write(@filename, content)
    end
  end
end
