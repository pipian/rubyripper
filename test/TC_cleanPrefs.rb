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
require 'rubyripper/preferences/cleanPrefs.rb'

# A class to test if the Cd-info is correctly parsed
class TC_CleanPrefs < Test::Unit::TestCase

	def setup
		@file = FakeFileAndDir.new 
		@clean = CleanPrefs.new(@file)
		ENV['HOME'] = '/home/test'
	end

	# test in case of normal behaviour
	def test_cleanup
		@clean.cleanup()
		assert_equal('/home/test/.rubyripper_settings', @file.usage['remove'][0])
		assert_equal('/home/test/.rubyripper/freedb.yaml', @file.usage['remove'][1])
		assert_equal('/home/test/.rubyripper/settings', @file.usage['remove'][2])
		assert_equal('/home/test/.rubyripper', @file.usage['remove'][3])
	end
end
