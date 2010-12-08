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

# This class will fake the file and directory operations of Ruby
class FakeFileAndDir
attr_reader :locations, :fileContent

	def initialize
		@fileContent = Array.new
		@dirnames = [ENV['HOME']]
		@filenames = Array.new
	end

	# file including dir
	def addFile(filename)
		@filenames << filename
	end

	def mkdir(dir)
		@dirnames << dir
	end

	def exists?(filenames)
		return @filenames.include?(location)
	end

	def file?(file)
		return @filenames.include?(file)
	end

	def directory?(dir)
		return @dirnames.include?(dir)
	end

	def write(content)
		@fileContent << content
	end

	def open(file, writemodus)
		@filenames << file
		yield(self)
	end
end
