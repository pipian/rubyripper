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

# This class will cleanup previous Rubyripper files
class FilePrefs
	def initialize(fileAndDir)
		@file = fileAndDir
	end

		# help function to create dirs
	def createDirs(dirName)
		if !File.directory?(File.dirname(dirName))
			createDirs(File.dirname(dirName))
		end
	
		if !File.directory?(dirName)
			Dir.mkdir(dirName)
		end
	end

	# check for existing configs in old directories and move them
	# to the standard directories conform the freedesktop.org spec
	def migrationCheck()
		oldDir = File.join(ENV['HOME'], '.rubyripper')
		if File.directory?(oldDir)
			puts "Auto migrating to new file locations..."
			oldConfig = File.join(ENV['HOME'], '.rubyripper/settings')
			oldCache = File.join(ENV['HOME'], '.rubyripper/freedb.yaml')
			moveFiles(oldConfig, oldCache)
			deleteOldDir(oldDir)
		end

		# clean up a very old config file
		if File.exists?(oldFile = File.join(ENV['HOME'], '.rubyripper_settings'))
			FileUtils.rm(oldFile)
		end
	end

	# help function to move the files
	def moveFiles(oldConfig, oldCache)
		if File.exists?(oldConfig)
			FileUtils.mv(oldConfig, @configFile)
			puts "New location of config file: #{@configFile}"
		end

		if File.exists?(oldCache)
			FileUtils.mv(oldCache, @cacheFile)
			puts "New location of freedb file: #{@cacheFile}"
		end
	end

	# help function to remove the old dir
	def deleteOldDir(oldDir)
		if File.symlink?(oldDir)
			File.delete(oldDir)
		elsif Dir.entries(oldDir).size > 2 # some leftover file(s) remain
			puts "#{oldDir} could not be removed: it's not empty!"
		else
			Dir.delete(oldDir)
		end
		puts "Auto migration finished succesfull."
	end
end
