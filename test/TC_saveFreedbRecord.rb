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

require './mocks/FakeFileAndDir.rb'
require 'rubyripper/freedb/saveFreedbRecord.rb'

# A class to test SaveFreedbRecord class
class TC_SaveFreedbRecord < Test::Unit::TestCase

	def setup
		ENV['HOME'] = '/home/test'
		@file = FakeFileAndDir.new
		@save = SaveFreedbRecord.new(@file)
	end

	# test for new location
	def test_saveOnce
		file = File.read(File.join($localdir, 'data/freedb/disc001'))
		@save.save(file, 'strange', 'ABCDEFGH')
		
		assert_equal('/home/test/.cddb/strange/ABCDEFGH', 
@file.usage['write'][0][0])
		assert_equal(file, @file.usage['write'][0][1])
	end

	# test for existing location, it shouldn't overwrite
	def test_saveTwiceSameLocation
		file001 = File.read(File.join($localdir, 'data/freedb/disc001'))
		file002 = File.read(File.join($localdir, 'data/freedb/disc002'))
		@save.save(file001, 'strange', 'ABCDEFGH')
		@save.save(file002, 'strange', 'ABCDEFGH')

		assert_not_equal(file002, @file.usage['write'][0][1])
		assert_equal(1, @file.usage['write'].length)
	end
end
