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

require 'rubyripper/system/dependency'
require 'rubyripper/system/fileAndDir'

module Preferences
  class Load

    # setting up instances
    def initialize(customFilename, out=$stdout, fileAndDir=nil, prefs=nil, deps=nil)
      @file = fileAndDir ? fileAndDir : FileAndDir.instance
      @prefs = prefs ? prefs : Preferences::Main.instance
      @deps = deps ? deps : Dependency.instance
      @out = out

      validateCustomFilename(customFilename)
      readPreferencesFromFile() if File.exists?(@prefs.filename)
      setValidCdromDrive()
    end

private

    # check if the file exists, if not return to defaults
    def validateCustomFilename(customFilename)
      @prefs.filename = customFilename if File.exists?(customFilename)
    end

    # read all preferences from the file
    def readPreferencesFromFile
      @file.read(@prefs.filename).each_line do |line|
        key, value = getNextPreference(line)
        updatePreference(key,value) unless value.nil?
      end
    end
    
    # make sure the user has a valid drive set
    def setValidCdromDrive
      if not @file.exists?(@prefs.cdrom)
        @prefs.cdrom = @deps.cdrom
      end
    end

    # convert the lines into key and values
    def getNextPreference(line)
      key, value = line.split('=', 2)
      # remove the trailing newline character
      value.rstrip!
      # replace the strings false/true with a bool
      if value == "false" ; value = false
      elsif value == "true" ; value = true
      # replace two quotes with an empty string
      elsif value.empty? ; value = ''
      elsif value == "''" ; value = ''
      # replace an integer string with an integer
      elsif value.to_i > 0 || value == '0' ; value = value.to_i
      end

      return [key, value]
    end

    # try to update the data object
    def updatePreference(key,value)
      key = (key+'=').to_sym
      if @prefs.data.respond_to?(key)
        @prefs.data.send(key, value)
      else
        @out.puts("WARNING: Preference with key #{key} does not exist")
      end
    end
  end
end
