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

require 'rubyripper/preferences/data'
require 'rubyripper/preferences/cleanup'
require 'rubyripper/preferences/setDefaults'
require 'rubyripper/preferences/load'
require 'rubyripper/preferences/save'

module Preferences

  class Main
  attr_reader :data
  attr_accessor :filename

    def initialize(out=$stdout)
      @data = Data.new
      @filename = getDefaultFilename()
      @out = out
    end

    # load the preferences after setting the defaults
    def load(customFilename="")
      Cleanup.new()
      SetDefaults.new(self)
      Load.new(self, customFilename, @out)
    end

    # save the preferences
    def save()
      Save.new(self)
    end

   private

    # if the method is not found try to look it up in the data object
    def method_missing(name, *args)
      @data.send(name, *args)
    end

    # return the default filename
    def getDefaultFilename
      dir = ENV['XDG_CONFIG_HOME'] || File.join(ENV['HOME'], '.config')
      File.join(dir, 'rubyripper/settings')
    end
  end
end
