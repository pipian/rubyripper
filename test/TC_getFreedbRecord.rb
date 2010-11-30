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

require 'rubyripper/freedb/getFreedbRecord.rb'

# create mock for http traffic
class FakeConnection
	
	# query = first response, read = freedbRecord, category = genre, discid = discid
	def initialize(query, read, category, discid)
		update(query, read, category, discid)
	end

	# skip http configuration, faking the connection
	def configConnection(url)
	end

	# refresh the variables
	def update (query, read, category, discid)
		@query = query
		@read = read
		@category = category
		@discid = discid
	end

	# simulate server response and validate query
	def get(query)
		if query.include?('query')
			return @query
		elsif query.include?('read')
			raise "Category not found: #{query}" unless query.include?(@category)
			raise "Connection not found: #{query}" unless query.include?(@discid)
			return @read
		else
			raise "query #{query} not recognized"
		end
	end
end

# A class to test if GetFreedbRecord conforms to the Freedb protocol
class TC_GetFreedbRecord < Test::Unit::TestCase
	# make all instances necessary only one
	def setup
		@freedbString = "7F087C0A 10 150 13359 36689 53647 68322 81247 87332 \
106882 122368 124230 2174"
		@file001 = File.read(File.join($localdir, 'data/freedb/disc001'))
	end

	# test when no records found
	def test_NoRecordsFound
		# prepare test
		query = '202 No match found'
		read = ''
		mock = FakeConnection.new(query, read, '', '')
		instance = GetFreedbRecord.new(@freedbString, $settings, mock)

		# execute test
		assert_equal('noMatches', instance.status[0])
		assert_equal('', instance.freedbRecord)
		assert_equal([], instance.getChoices)
	end

	# test when single record found
	def test_SingleRecordFound
		# prepare test
		query = '200 blues 7F087C0A Some random artist / Some random album'
		read = "210 metal 7F087C01\n" + @file001 + "\n."
		category = 'blues'
		discid = '7F087C0A'
		mock = FakeConnection.new(query, read, category, discid)
		instance = GetFreedbRecord.new(@freedbString, $settings, mock)

		# execute test
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)
		assert_equal([], instance.getChoices)
		assert_equal('metal', instance.category)
		assert_equal('7F087C01', instance.discId)
	end

	# test when multiple records found
	def test_MultipleRecordsFound
		# prepare test
		$settings['firstHit'] = false
		choices = "blues 7F087C0A Artist A / Album A\n\
#rock 7F087C0B Artist B / Album B\n\
#jazz 7F087C0C Artist C / Album C\n\
#country 7F087C0D Artist D / Album D\n."
		query = "211 code close matches found\n#{choices}"
		read = "210 blues 7F087C0A\n" + @file001 + "\n."
		category = ''
		discid = ''
		mock = FakeConnection.new(query, read, category, discid)
		instance = GetFreedbRecord.new(@freedbString, $settings, mock)

		# execute test, user has to choose first before record is shown
		assert_equal('multipleRecords', instance.status[0])
		assert_equal('', instance.freedbRecord)
		assert_equal(choices[0..-3], instance.getChoices().join("\n"))
		
		# choose 1st option
		mock.update(query, read, 'blues', '7F087C0A')
		instance.choose(0)
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)

		# choose 2nd option
		mock.update(query, read, 'rock', '7F087C0B')
		instance.choose(1)
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)

		# choose 3rd option
		mock.update(query, read, 'jazz', '7F087C0C')
		instance.choose(2)
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)

		# choose 4th option
		mock.update(query, read, 'country', '7F087C0D')
		instance.choose(3)
		assert_equal('ok', instance.status[0])
		assert_equal(@file001, instance.freedbRecord)

		# choose 5th option (there is NONE !!)
		assert_raise ArgumentError do instance.choose(4) end
		
		# test with firstHit == true
		$settings['firstHit'] = true
		mock.update(query, read, 'blues', '7F087C0A')
		instance = GetFreedbRecord.new(@freedbString, $settings, mock)
		assert_equal(@file001, instance.freedbRecord)
		assert_equal('ok', instance.status[0])
	end

	# test when freedb replies the database is corrupt
	def test_databaseCorrupt
		# prepare test
		query = '403 Database entry is corrupt'
		read = ''
		mock = FakeConnection.new(query, read, '', '')
		instance = GetFreedbRecord.new(@freedbString, $settings, mock)

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
		mock = FakeConnection.new(query, read, '', '')
		instance = GetFreedbRecord.new(@freedbString, $settings, mock)

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
		category = 'blues'
		discid = '7F087C0A'
		mock = FakeConnection.new(query, read, category, discid)
		instance = GetFreedbRecord.new(@freedbString, $settings, mock)

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
		category = 'blues'
		discid = '7F087C0A'
		mock = FakeConnection.new(query, read, category, discid)
		instance = GetFreedbRecord.new(@freedbString, $settings, mock)

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
		category = 'blues'
		discid = '7F087C0A'
		mock = FakeConnection.new(query, read, category, discid)
		instance = GetFreedbRecord.new(@freedbString, $settings, mock)

		# execute test
		assert_equal('databaseCorrupt', instance.status[0])
		assert_equal('', instance.freedbRecord)
		assert_equal([], instance.getChoices)
	end
end
