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

# A class to test SaveFreedbRecord class
class TC_SaveFreedbRecord < Test::Unit::TestCase

	def setup
		@save = SaveFreedbRecord.new
	end

	# test for new location
	def test_saveOnce
		file = File.read(File.join($localdir, 'data/freedb/disc001'))
		@save.save(file, 'strange', 'ABCDEFGH')
		assert(File.exists?(@save.outputFile))
		assert_equal(file, File.read(@save.outputFile))
	end

	# test for existing location, it shouldn't overwrite
	def test_saveTwiceSameLocation
		file001 = File.read(File.join($localdir, 'data/freedb/disc001'))
		file002 = File.read(File.join($localdir, 'data/freedb/disc002'))
		@save.save(file001, 'strange', 'ABCDEFGH')
		@save.save(file002, 'strange', 'ABCDEFGH')

		assert(File.exists?(@save.outputFile))
		assert_not_equal(file002, File.read(@save.outputFile))
	end
	
	# clean up
	def teardown
		File.delete(@save.outputFile)
		Dir.rmdir(File.dirname(@save.outputFile))
	end
end
