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

require './mocks/FakePreferences.rb'
require './mocks/FakeHttpConnection.rb'
require 'rubyripper/freedb/getFreedbRecord.rb'

# A class to test if GetFreedbRecord conforms to the Freedb protocol
class TC_GetFreedbRecord < Test::Unit::TestCase
	# make all instances necessary only one
	def setup
		@freedbString = "7F087C0A 10 150 13359 36689 53647 68322 81247 87332 \
106882 122368 124230 2174"
		@queryRequest = "/~cddb/cddb.cgi?cmd=cddb+query+7F087C0A+10+150+13359+\
36689+53647+68322+81247+87332+106882+122368+124230+2174&hello=Joe+\
fakestation+rubyripper+test&proto=6"
		@file001 = File.read(File.join($localdir, 'data/freedb/disc001'))
		@preferences = {'hostname'=>'fakestation', 'username'=>'Joe', 
'firstHit'=>false, 'site'=> "http://freedb.freedb.org/~cddb/cddb.cgi"}
	end

	# test when no records found
	def test_NoRecordsFound
		# prepare test
		query = '202 No match found'
		read = ''
		mock = FakeHttpConnection.new(query, read)
		@prefs = FakePreferences.new(@preferences)
		instance = GetFreedbRecord.new(@freedbString, @prefs, mock)

		# execute test to verify input for FakeHttpConnection
		readRequest = nil
		assert_equal(true, mock.config)
		assert_equal(@queryRequest, mock.inputQuery[0])
		assert_equal(readRequest, mock.inputQuery[1])
		
		# execute test to verify output
		assert_equal('noMatches', instance.status[0])
		assert_equal('', instance.freedbRecord)
		assert_equal([], instance.getChoices)
	end

	# test when single record found
	def test_SingleRecordFound
		# prepare test
		query = '200 blues 7F087C0A Some random artist / Some random album'
		read = "210 metal 7F087C01\n" + @file001 + "\n."
		mock = FakeHttpConnection.new(query, read)
		@prefs = FakePreferences.new(@preferences)
		instance = GetFreedbRecord.new(@freedbString, @prefs, mock)

		# execute test to verify input for FakeHttpConnection
		readRequest = "/~cddb/cddb.cgi?cmd=cddb+read+blues+7F087C0A&hello=\
Joe+fakestation+rubyripper+test&proto=6"
		assert_equal(true, mock.config)
		assert_equal(@queryRequest, mock.inputQuery[0])
		assert_equal(readRequest, mock.inputQuery[1])

		# execute test to verify output
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)
		assert_equal([], instance.getChoices)
		assert_equal('metal', instance.category)
		assert_equal('7F087C01', instance.discId)
	end

	# test when multiple records found
	def test_MultipleRecordsFound
		# prepare test
		@preferences['firstHit'] = false
		choices = "blues 7F087C0A Artist A / Album A\n\
rock 7F087C0B Artist B / Album B\n\
jazz 7F087C0C Artist C / Album C\n\
country 7F087C0D Artist D / Album D\n."
		query = "211 code close matches found\n#{choices}"
		read = "210 blues 7F087C0A\n" + @file001 + "\n."
		mock = FakeHttpConnection.new(query, read)
		@prefs = FakePreferences.new(@preferences)
		instance = GetFreedbRecord.new(@freedbString, @prefs, mock)

		# execute test, user has to choose first before record is shown
		assert_equal(true, mock.config)
		assert_equal(@queryRequest, mock.inputQuery[0])
		assert_equal('multipleRecords', instance.status[0])
		assert_equal('', instance.freedbRecord)
		assert_equal(choices[0..-3], instance.getChoices().join("\n"))
		
		# choose 1st option
		mock.update(query, read)
		instance.choose(0)
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)

		# execute test to verify input for FakeHttpConnection
		readRequest = "/~cddb/cddb.cgi?cmd=cddb+read+blues+7F087C0A&hello=\
Joe+fakestation+rubyripper+test&proto=6"
		assert_equal(readRequest, mock.inputQuery[-1])

		# choose 2nd option
		mock.update(query, read)
		instance.choose(1)
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)

		# execute test to verify input for FakeHttpConnection
		readRequest = "/~cddb/cddb.cgi?cmd=cddb+read+rock+7F087C0B&hello=\
Joe+fakestation+rubyripper+test&proto=6"
		assert_equal(readRequest, mock.inputQuery[-1])

		# choose 3rd option
		mock.update(query, read)
		instance.choose(2)
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)

		# execute test to verify input for FakeHttpConnection
		readRequest = "/~cddb/cddb.cgi?cmd=cddb+read+jazz+7F087C0C&hello=\
Joe+fakestation+rubyripper+test&proto=6"
		assert_equal(readRequest, mock.inputQuery[-1])

		# choose 4th option
		mock.update(query, read)
		instance.choose(3)
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)

		# execute test to verify input for FakeHttpConnection
		readRequest = "/~cddb/cddb.cgi?cmd=cddb+read+country+7F087C0D&hello=\
Joe+fakestation+rubyripper+test&proto=6"
		assert_equal(readRequest, mock.inputQuery[-1])

		# choose 5th option (there is NONE !!)
		assert_raise ArgumentError do instance.choose(4) end
		
		# test with firstHit == true
		@preferences['firstHit'] = true
		mock.update(query, read)
		@prefs = FakePreferences.new(@preferences)
		instance = GetFreedbRecord.new(@freedbString, @prefs, mock)
		assert_equal(@file001, instance.freedbRecord)
		assert_equal('ok', instance.status[0])

		# execute test to verify input for FakeHttpConnection
		readRequest = "/~cddb/cddb.cgi?cmd=cddb+read+blues+7F087C0A&hello=\
Joe+fakestation+rubyripper+test&proto=6"
		assert_equal(readRequest, mock.inputQuery[-1])
	end

	# test when freedb replies the database is corrupt
	def test_databaseCorrupt
		# prepare test
		query = '403 Database entry is corrupt'
		read = ''
		mock = FakeHttpConnection.new(query, read)
		@prefs = FakePreferences.new(@preferences)
		instance = GetFreedbRecord.new(@freedbString, @prefs, mock)

		# execute test
		assert_equal('databaseCorrupt', instance.status[0])
		assert_equal('', instance.freedbRecord)
		assert_equal([], instance.getChoices)
	end

	# test when freedb replies with an unknown return code
	def test_unknownCode
		# prepare test
		query = '666 The Number of the beast'
		read = ''
		mock = FakeHttpConnection.new(query, read)
		@prefs = FakePreferences.new(@preferences)
		instance = GetFreedbRecord.new(@freedbString, @prefs, mock)

		# execute test
		assert_equal('unknownReturnCode', instance.status[0])
		assert_equal("cddb_query return code = 666.\n\
Return code is not supported.", instance.status[1])
		assert_equal('', instance.freedbRecord)
		assert_equal([], instance.getChoices)
	end

	# test when read command has 401 error (specified CDDB entry not found)
	def test_CddbEntryNotFound
		# prepare test
		query = '200 blues 7F087C0A Some random artist / Some random album'
		read = "401 Specified CDDB entry not found"
		mock = FakeHttpConnection.new(query, read)
		@prefs = FakePreferences.new(@preferences)
		instance = GetFreedbRecord.new(@freedbString, @prefs, mock)

		# execute test
		assert_equal('cddbEntryNotFound', instance.status[0])
		assert_equal('', instance.freedbRecord)
		assert_equal([], instance.getChoices)
	end

	# test when read command has 402 error (server error)
	def test_serverError
		# prepare test
		query = '200 blues 7F087C0A Some random artist / Some random album'
		read = "402 Server error"
		mock = FakeHttpConnection.new(query, read)
		@prefs = FakePreferences.new(@preferences)
		instance = GetFreedbRecord.new(@freedbString, @prefs, mock)

		# execute test
		assert_equal('serverError', instance.status[0])
		assert_equal('', instance.freedbRecord)
		assert_equal([], instance.getChoices)
	end

	# test when read command has 403 error (server error)
	def test_serverError
		# prepare test
		query = '200 blues 7F087C0A Some random artist / Some random album'
		read = "403 Server error"
		mock = FakeHttpConnection.new(query, read)
		@prefs = FakePreferences.new(@preferences)
		instance = GetFreedbRecord.new(@freedbString, @prefs, mock)

		# execute test
		assert_equal('databaseCorrupt', instance.status[0])
		assert_equal('', instance.freedbRecord)
		assert_equal([], instance.getChoices)
	end
end
