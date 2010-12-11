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
require 'rubyripper/freedb/loadFreedbRecord.rb'

# A class to test if loadFreedbRecord succesfully finds and loads a local file
class TC_LoadFreedbRecord < Test::Unit::TestCase

	# first set a file ready
	def setup
		@file = FakeFileAndDir.new()
		@load = LoadFreedbRecord.new(@file)
	end

	# test if no files are found
	def test_noFilesFound
		@file.data['glob'] << Array.new
		@load.scan('nonsense')

		assert_equal('noRecords', @load.status)
		assert_equal(String.new, @load.freedbRecord)
	end

	# test if only one file found
	def test_oneFileFound
		@file.data['glob'] << ['/test/ABCDEFGH']
		@file.data['read'] << 'sampleText'
		@load.scan('ABCDEFGH')

		assert_equal('ok', @load.status)
		assert_equal('sampleText', @load.freedbRecord)
		assert_equal('/test/ABCDEFGH', @file.usage['read'][0])	
	end

	# test if two files are found
	def test_twoFilesFound
		@file.data['glob'] << ['/test/jazz/ABCDEFGH', '/test/blues/ABCDEFGH']
		@file.data['read'] << 'sampleText'
		@load.scan('ABCDEFGH')

		assert_equal('ok', @load.status)
		assert_equal('sampleText', @load.freedbRecord)
		assert_equal('/test/jazz/ABCDEFGH', @file.usage['read'][0])	
	end

	# When importing directly in UTF-8 fails, try with ISO-8859-1 encoding
	def test_88591_encoding
		@file.data['glob'] << ['/test/blues/ABCDEFGH']
		@file.data['read'] << "validEncoding"
		@file.data['read'] << "hello red \xE8".force_encoding("UTF-8")

		@load.scan('ABCDEFGH')

		assert_equal('ok', @load.status)
		assert_equal('validEncoding', @load.freedbRecord)
		assert_equal('/test/blues/ABCDEFGH', @file.usage['read'][0])	
	end

	# When importing fails twice, set status to InvalidEncoding
	def test_importing_fails
		@file.data['glob'] << ['/test/blues/ABCDEFGH']
		@file.data['read'] << "hello red \xE8".force_encoding("UTF-8")
		@file.data['read'] << "hello red \xE8".force_encoding("UTF-8")
		@load.scan('ABCDEFGH')

		assert_equal('InvalidEncoding', @load.status)
		assert_equal('', @load.freedbRecord)
		assert_equal('/test/blues/ABCDEFGH', @file.usage['read'][0])	
	end
end
