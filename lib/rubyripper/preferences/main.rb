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
require 'rubyripper/preferences/setDefaults'
require 'rubyripper/preferences/load'
require 'rubyripper/preferences/save'

# WILL OBSOLETE handlePrefs.rb
# The settings class is responsible for:
# managing the settings during a session
module Preferences
  DATA = Data.new
  FILENAME = getDefaultFilename()

  def getDefaultFilename

  end

  class Main

    # load the preferences after setting the defaults
    def load(preferencesFile=false)
      #Cleanup.new
      SetDefaults.new
      @preferencesFile = Load.new(preferencesFile)
    end

    # save the preferences
    def save()
      Save.new()
    end

    # if the method is not found try to look it up in the data object
    def method_missing(name, *args)
      DATA.send(name, *args)
    end
  end
end


#     # setup the instances
#     def initialize(deps=nil)
#       @deps = deps ? deps : Dependency.new
#       @prefs = Hash.new()
#     end
#
#     # update the settings with the info from loadPrefs
#     # also check if @load has all the keys
#     def update(results)
#       results.each do |key, value|
#         if @prefs.key?(key)
#           @prefs[key] = value
#         else
#           puts "WARNING: invalid setting: #{key}"
#         end
#       end
#
#       results.each do |key, value|
#         if results[key].nil?
#           puts "WARNING: #{key} is missing in config file!"
#         end
#       end
#     end
#   end
# end