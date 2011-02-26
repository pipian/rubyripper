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

# require fileToBeTested

# A class to test if to_be_tested_ruby_file does <X> correctly
class TC_ClassToBeTested < Test::Unit::TestCase
	# make all instances necessary only one
	def setup
		# @failed = load input if command failed (when relevant)
		# @file001 = load input for instance 1
		# @file002 = load input for instance 2
		# @instFailed = ClassToBeTested.new(@failed)
		# @inst001 = ClassToBeTested.new(@file001)
		# @inst002 = ClassToBeTested.new(@file002)
	end

	# Note that the arguments are already tested in the class itself
	# The return type and methods are already tested in the different instances
	# Make sure not only the happy flow is tested, also include the error cases!
	# The error cases are set above the tests for the happy flow

	# When the class to be tested is parsing some text, allow handling the text
	# directly to the class, so it can easily be tested.
	# All sample texts are saved in test/data
	# Test all the information that should be parsed with the sample file.
	# Test all public methods for correctness

	# Only publicly accessible functions or variables are tested

	# run all tests, all functions that start with test are loaded
	def testSuite
		if_failed() # (when relevant)
		instance001()
		instance002()
		instance003()
		instance004()
		instance005()
	end

	# test when the input app has failed
	def if_failed
	end

	# test if inst001 passes (short explanation)
	def instance001
	end

	# test if inst002 passes (short explanation)
	def instance002
	end

	# test if inst003 passes (short explanation)
	def instance003
	end

	# test if inst004 passes (short explanation)
	def instance004
	end

	# test if inst005 passes (short explanation)
	def instance005
	end
end
