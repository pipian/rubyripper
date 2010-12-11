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

require './mocks/FakeOutput.rb'
require './mocks/FakeInput.rb'
require 'rubyripper/cli/cliGetAnswer.rb'

# A class to test if the class returns proper answers
class TC_GetAnswer < Test::Unit::TestCase
	
	# overriding input and output
	def setup
		$stdout, @backup_out = FakeOutput.new, $stdout
		$stdin, @backup_in = FakeInput.new, $stdin
	end

	# restore input and output
	def teardown
		$stdout = @backup_out
		$stdin = @backup_in
	end

	# test if the input mock works properly
	def test_00InputMock
		
		# with one line in it
		$stdin.add(text = 'hello world!')
		assert_equal(text, $stdin.gets)
		assert_equal('', $stdin.gets)

		# with two lines in it, using FIFO
		$stdin.add(text1 = 'hello world!')
		$stdin.add(text2 = 'bye, bye...')
		assert_equal(text1, $stdin.gets)
		assert_equal(text2, $stdin.gets)
		assert_equal('', $stdin.gets)

		#$stdin, $stdout = oldin, oldout 
	end

	# test if the output mock works properyly
	def test_OutputMock
		assert_equal(nil, $stdout.gets)
		
		# with one line in it
		print text="Hello World!"
		assert_equal(text, $stdout.gets)
		assert_equal(nil, $stdout.gets)

		# with two lines in it, using LIFO
		print text1 = 'hello world!'
		print text2 = 'bye, bye...'
		assert_equal(text2, $stdout.gets)
		assert_equal(text1, $stdout.gets)
		assert_equal(nil, $stdout.gets)

	end

	# test GetInt class
	def test_GetInt
		@int = GetInt.new

		# test in case an integer 0-10 is typed
		(0..10).each do |number|
			$stdin.add(number.to_s)
			assert_equal(number, @int.get('question', 100))
		end

		# test in case a string is given and then an int
		$stdin.add('hello')
		$stdin.add('10')
		assert_equal(10, @int.get('question', 100))

		# test in case nothing is given, the default is used
		assert_equal(100, @int.get('question', 100))
	end

	# test GetBool class
	def test_GetBool
		@bool = GetBool.new

		valid = {_("yes") => true, _('y') => true, 
_("no") => false, _("n") =>false}
		
		# test for valid input
		valid.each do |key, value|
			$stdin.add(key)
			assert_equal(value, @bool.get('question', 'dontknow'))
		end

		# test for invalid input and then correct it
		$stdin.add('crazy')
		$stdin.add(_('y'))
		assert_equal(true, @bool.get('question', 'n'))

		# test in case nothing is given, the default is used
		assert_equal(false, @bool.get('question', 'n')) 
	end

	# test GetString class
	def test_GetString
		@string = GetString.new
		strings = ['goodbye', 'oh', 'cruel', 'world']

		# test for valid input
		strings.each do |string|
			$stdin.add(string)
			assert_equal(string, @string.get('question', 'ok'))
		end

		# test in case nothing is given, the default is used
		assert_equal('happy', @string.get('question', 'happy'))
	end
end
