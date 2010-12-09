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

# This class will help with the file and directory operations of Ruby
class FileAndDir

	def mkdir(dir)
		Dir.mkdir(dir)
	end

	def exists?(filename)
		return File.exists?(filename)
	end

	def file?(file)
		return File.file?(file)
	end

	def directory?(dir)
		return File.directory?(dir)
	end

	# create any directories that are needed for the filename
	def createDirs(filename)
		dirs = Array.new

		# find all directories that do not exist yet
		# first entry will be the dirname, than it's parent and so on
		while (!File.directory?(dir = File.dirname(filename)))
			dirs << dir
			filename = dir
		end
		
		# now create the dirs, starting with the main parent
		while !dirs.empty?
			Dir.mkdir(dirs.pop())
		end
	end

	# filename = Name of the new file
	# content = A string with the content of the new file
	# force = overwrite if file exists
	def write(filename, content, force = false)
		status = false
		if File.file?(filename) && force == false
			status = 'fileExists'
		else
			createDirs(filename)
			
			File.open(filename, 'w') do |file|
				file.write(content)
			end

			status = 'ok'
		end

		return status
	end
end
