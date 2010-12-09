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

# This class will try to load the Rubyripper config file
# It does not validate if the keys are valid, this is done in preferences
class LoadPrefs

	# * fileAndDir = instance of FileAndDir
	def initialize(fileAndDir)
		@file = fileAndDir
		@settings = Hash.new
		@configFound = false
		@configFile = String.new
	end

	# return the setting, if unknown return nil
	def get(setting) ; return @settings[setting] ; end

	# return all settings
	def getAll ; return @settings ; end

	# if config is found
	def configFound ; return @configFound ; end

	# return configFile
	def configFile ; return @configFile ; end

	# load the configFile
	def loadConfig(default, filename = false)
		filename = findFile(default, filename)
		loadFile(filename)
		@configFile = filename
	end

private

	# find the location of the config file
	def findFile(default, filename)
		filename = @file.exists?(filename) if filename.class == String
		filename == false ? filename = default : @configFound = true
		return filename
	end

	# first the values found in the config file, then add any missing values
	def loadFile(filename)
		@file.read(filename).each_line do |line|
			key, value = line.split('=', 2)
			# remove the trailing newline character
			value.rstrip!
			# replace the strings false/true with a bool
			if value == "false" ; value = false 
			elsif value == "true" ; value = true
			# replace two quotes with an empty string
			elsif value == "''" ; value = ''
			# replace an integer string with an integer 
			elsif value.to_i > 0 || value == '0' ; value = value.to_i
			end

			@settings[key] = value
		end
	end
end
