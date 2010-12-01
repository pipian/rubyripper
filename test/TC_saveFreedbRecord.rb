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

require 'rubyripper/freedb/saveFreedbRecord.rb'

# A class to test if to_be_tested_ruby_file does <X> correctly
class TC_SaveFreedbRecord < Test::Unit::TestCase

	# test for new location
	def test_01newlocation
		file = File.read(File.join($localdir, 'data/freedb/disc001'))
		instance = SaveFreedbRecord.new(file, 'strange', 'ABCDEFGH')
		assert(File.exists?(instance.outputFile))
		assert_equal(file, File.read(instance.outputFile))
	end

	# test for existing location, the number is edited to ensure 01 runs first
	def test_02existingLocation
		file = File.read(File.join($localdir, 'data/freedb/disc002'))
		instance = SaveFreedbRecord.new(file, 'strange', 'ABCDEFGH')
		assert(File.exists?(instance.outputFile))
		assert_not_equal(file, File.read(instance.outputFile))
		
		# clean up
		File.delete(instance.outputFile)
		Dir.rmdir(File.dirname(instance.outputFile))
	end
end
