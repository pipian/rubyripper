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
require 'rubyripper/preferences/loadPrefs.rb'

# A class to test if the Cd-info is correctly parsed
class TC_LoadPrefs < Test::Unit::TestCase

	def setup
		@file = FakeFileAndDir.new 
		@load = LoadPrefs.new(@file)
		@default = '/home/test/.config/rubyripper/settings'
	end

	# test in case the file is invalid and there is no home backup
	def test_FakeFileNoHome
		@file.readLines << ''		
		filename = File.join($localdir, 'data/settings/doesNotExist')
		@load.loadConfig(@default, filename)
		
		assert_equal(false, @load.configFound)
		assert_equal('/home/test/.config/rubyripper/settings',
@file.filenames[0])
		assert_equal(0, @load.getAll.length)
	end

	# test in case the file is invalid and there is a home backup
	def test_FakeFileWithHome
		@file.readLines << "test=true\nfaking=false\nempty=\'\'\n\
time=0\ntea=1"		
		filename = File.join($localdir, 'data/settings/doesNotExist')
		@load.loadConfig(@default, filename)
		
		assert_equal(false, @load.configFound)
		assert_equal('/home/test/.config/rubyripper/settings',
@file.filenames[0])
		assert_equal(5, @load.getAll.length)

		assert_equal(true, @load.get('test'))
		assert_equal(false, @load.get('faking'))
		assert_equal(true, @load.get('empty').empty?)
		assert_equal(0, @load.get('time'))
		assert_equal(1, @load.get('tea'))		
	end

	# test in case the file is found
	def test_RealFile
		filename = File.join($localdir, 'data/settings/settings001')
		@file.readLines << File.read(filename)
		@file.filenames << filename
		@load.loadConfig(@default, filename)

		assert_equal(true, @load.configFound)
		assert_equal(filename, @file.filenames[-1])
		assert_equal(45, @load.getAll.length)

		# just test the different types
		assert_equal(true, @load.get('flac'))
		assert_equal(false, @load.get('noSpaces'))
		assert_equal('--best -V', @load.get('settingsFlac'))
		assert_equal(5, @load.get('maxTries'))
		assert_equal(0, @load.get('offset'))
		assert_equal(String.new, @load.get('rippersettings'))
	end
end
