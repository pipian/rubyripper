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

require 'rubyripper/freedb/loadFreedbRecord.rb'
require 'rubyripper/freedb/saveFreedbRecord.rb'

# A class to test if loadFreedbRecord succesfully finds and loads a local file
class TC_LoadFreedbRecord < Test::Unit::TestCase

	# first set a file ready
	def setup
		@file001 = File.read(File.join($localdir, 'data/freedb/disc001'))
		@file006 = File.read(File.join($localdir, 'data/freedb/disc006'))
		@inst001 = SaveFreedbRecord.new(@file001, 'strange', 'ABCDEFGH')
		@inst002 = SaveFreedbRecord.new(@file001, 'strange', '01234567')
		@inst003 = SaveFreedbRecord.new(@file001, 'weird', '01234567')
		@inst004 = SaveFreedbRecord.new(@file006, 'weird', 'ZZYYXXWW')
	end

	# test if no files are found
	def test_noFilesFound
		disc000 = LoadFreedbRecord.new('nonsense')
		assert_equal('noRecords', disc000.status)
		assert_equal(String.new, disc000.freedbRecord)
	end

	# test if only one file found
	def test_oneFileFound
		disc001 = LoadFreedbRecord.new('ABCDEFGH')
		assert_equal('ok', disc001.status)
		assert_equal(@file001, disc001.freedbRecord)
	end

	# test if two files are found
	def test_twoFilesFound
		disc002 = LoadFreedbRecord.new('01234567')
		assert_equal('ok', disc002.status)
		assert_equal(@file001, disc002.freedbRecord)	
	end

	# test if file with ISO-8859-1 encoding is converted to UTF-8
	def test_88591_encoding
		disc004 = LoadFreedbRecord.new('ZZYYXXWW')
		assert_equal('ok', disc004.status)
		assert_equal(true, disc004.freedbRecord.valid_encoding?)	
		assert_equal('UTF-8', disc004.freedbRecord.encoding.name)
		assert(disc004.freedbRecord.length > 0)
	end
		
	# after all is done, clean up the files
	def teardown
		File.delete(@inst001.outputFile)
		File.delete(@inst002.outputFile)
		Dir.rmdir(File.dirname(@inst002.outputFile))
		File.delete(@inst003.outputFile)
		File.delete(@inst004.outputFile)
		Dir.rmdir(File.dirname(@inst004.outputFile))
	end
end
