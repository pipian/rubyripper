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

# A class that tries to locally find an entry in $HOME/.cddb
class LoadFreedbRecord
	
	# * discid = the discid as calculated for the freedb server
	def initialize(discid)
		@discid = discid
		checkArguments()

		@freedbRecord = ''
		@status = 'noRecords'
		scanLocal()
	end

	def freedbRecord ; return @freedbRecord ; end

	# return the status
	def status ; return @status ; end

private
	# check the arguments for the type
	def checkArguments
		unless @discid.class == String && @discid.length == 8
			raise ArgumentError, "discid must be a string of 8 characters"
		end
	end

	# Find all matches in the cddb directory
	def scanLocal
		dir = File.join(ENV['HOME'], '.cddb')
		@matches = Dir.glob("#{dir}/*/#{@discid}")

		if @matches.size > 0
			begin
				@freedbRecord = getFile(@matches[0])
				@status = 'ok'
			rescue EncodingError
				@status = 'Cannot determine file encoding'
			end
		end
	end

	# file helper because of different encoding madness, it should be UTF-8
	# The only plausible way to test this is reloading the file
	# String manipulation afterwards seems not possible
	# Ruby 1.8 does not have encoding support yet
	def getFile(path)
		freedb = String.new
		if freedb.respond_to?(:encoding)
			File.open(path, 'r:utf-8') do |file|
				freedb = file.read()
			end
		
			return freedb if freedb.valid_encoding?
	
			File.open(path, 'r:iso-8859-1') do |file|
				freedb = file.read()
			end
			
			if not freedb.valid_encoding?
				raise EncodingError, 'The encoding of the freedb file can not be determined'
			end

			return freedb.encode('UTF-8')
		else
			freedb = File.read(path)
		end
	end
end
