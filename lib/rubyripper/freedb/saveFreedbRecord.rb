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

# class helping to store the retrieved freedb record
# do this conform standards at location $HOME/.cddb/<category>/<discid>
class SaveFreedbRecord
	
	# * freedbRecord = the complete freedb record string with all metadata
	# * category = the freedb category, needed for saving locally
	# * discid = the discid, which is the filename
	def initialize(freedbRecord, category, discid)
		@freedbRecord = freedbRecord
		@category = category
		@discid = discid
		checkArguments()
		
		setNames()
		checkDir(@baseDir)
		checkDir(@categoryDir)
		saveDiscid()
	end
	
	# return the file location
	def outputFile ; return @outputFile ; end

private
	# check the arguments
	def checkArguments()
		unless @freedbRecord.class == String
			raise ArgumentError, "freedbrecord must be a string"
		end
	
		unless @category.class == String
			raise ArgumentError, "category must be a string"
		end

		unless @discid.class == String && @discid.length == 8
			raise ArgumentError, "discid must be a string of 8 characters"
		end
	end

	# set the dir names
	def setNames
		@baseDir = File.join(ENV['HOME'], '.cddb')
		@categoryDir = File.join(@baseDir, @category)
		@outputFile = File.join(@categoryDir, @discid)
	end

	# check if a dir exists, if not create it
	def checkDir(dir)
		if !File.directory?(dir)
			Dir.mkdir(dir)
		end
	end

	# if $HOME/.cddb/<category>/<discid> does nog exist, create it
	def saveDiscid
		if !File.file?(@outputFile)
			File.open(@outputFile, 'w') do |file|
				file.write(@freedbRecord)
			end
		end
	end
end
