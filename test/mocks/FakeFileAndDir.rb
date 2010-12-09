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
attr_accessor :filenames, :fileContent, :readLines

	def initialize
		@fileContent = Array.new
		@filenames = Array.new
		@readLines = Array.new
	end

	def exists?(filename)
		if @filenames.include?(filename)
			return filename
		else
			return false
		end
	end

	def read(filename)
		@filenames << filename
		return @readLines.pop()
	end

	def write(filename, content, force=false)
		if @filenames.include?(filename) && force == false
			status = 'FileExists'
		else
			@filenames << filename
			@fileContent << content
			status = 'ok'
		end

		return status
	end
end
