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
		file001 = File.read(File.join($localdir, 'data/freedb/disc001'))
		inst001 = SaveFreedbRecord.new(file001, 'strange', 'ABCDEFGH')
		assert(File.exists?(inst001.outputFile))
		assert_equal(file001, File.read(inst001.outputFile))
	end

	# test for existing location
	def test_02existingLocation
		file002 = File.read(File.join($localdir, 'data/freedb/disc002'))
		inst002 = SaveFreedbRecord.new(file002, 'strange', 'ABCDEFGH')
		assert(File.exists?(inst002.outputFile))
		assert_not_equal(file002, File.read(inst002.outputFile))
		
		# clean up
		File.delete(inst002.outputFile)
		Dir.rmdir(File.dirname(inst002.outputFile))
	end
end
