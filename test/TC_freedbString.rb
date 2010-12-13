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

require './mocks/FakeInput.rb'
require './mocks/FakeDependency.rb'
require './mocks/FakeScanDiscCdparanoia.rb'
require './mocks/FakeFireCommand.rb'
require 'rubyripper/freedb/freedbString.rb'

# A class to test the freedbstring generation
class TC_FreedbString < Test::Unit::TestCase

	def setup
		$stdout, @backup = FakeOutput.new, $stdout
		@deps = FakeDependency.new(Hash.new)
		@prefs = FakePreferences.new({'cdrom'=>'fakeDrive'})
		@disc = FakeScanDiscCdparanoia.new
		@fire = FakeFireCommand.new
		@discid = FakeScanDiscCdparanoia.new # behaves the same
	end

	def teardown
		@stdout = @backup
	end

	# test with discid as a helper
	def test_DiscId_helper
		freedb = "7F087C0A 10 150 13359 36689 53647 68322 81247 87332 \
106882 122368 124230 2174"
		start = {1=>0, 2=>13209, 3=>36539, 4=>53497, 5=>68172, 6=>81097, 
			7=>87182, 8=>106732, 9=>122218, 10=>124080}
		length = {1=>13209, 2=>23330, 3=>16958, 4=>14675, 5=>12925,
6=>6085, 7=>19550, 8=>15486, 9=>1862, 10=>38839}
		@disc.set(start, length)

		@deps.set('discid', true)
		@fire.add(freedb)

		string = FreedbString.new(@deps, @prefs, @disc, @fire, @discid)
		assert_equal('discid fakeDrive', @fire.last)
		assert_equal(freedb, string.getFreedbString.upcase)
		assert_equal(freedb.split()[0], string.getDiscId.upcase)
	end

	# test with cd-discid as a helper
	def test_CdDiscid_helper
		freedb = "7F087C0A 10 150 13359 36689 53647 68322 81247 87332 \
106882 122368 124230 2174"
		start = {1=>0, 2=>13209, 3=>36539, 4=>53497, 5=>68172, 6=>81097, 
			7=>87182, 8=>106732, 9=>122218, 10=>124080}
		length = {1=>13209, 2=>23330, 3=>16958, 4=>14675, 5=>12925,
6=>6085, 7=>19550, 8=>15486, 9=>1862, 10=>38839}
		@disc.set(start, length)

		@deps.set('cd-discid', true)
		@fire.add(freedb)

		string = FreedbString.new(@deps, @prefs, @disc, @fire, @discid)
		assert_equal('cd-discid fakeDrive', @fire.last)
		assert_equal(freedb, string.getFreedbString.upcase)
		assert_equal(freedb.split()[0], string.getDiscId.upcase)
	end

	# test when all fails
	def test_NoLuckToday
		string = FreedbString.new(@deps, @prefs, @disc, @fire, @discid)
		assert_equal('', string.getFreedbString)
		assert_equal('', string.getDiscId)
	end

	# test manual calculation with pure AudioDisc
	def test_NormalAudioDisc
		freedb = "7F087C0A 10 150 13359 36689 53647 68322 81247 87332 \
106882 122368 124230 2174"
		start = {1=>0, 2=>13209, 3=>36539, 4=>53497, 5=>68172, 6=>81097, 
			7=>87182, 8=>106732, 9=>122218, 10=>124080}
		length = {1=>13209, 2=>23330, 3=>16958, 4=>14675, 5=>12925,
6=>6085, 7=>19550, 8=>15486, 9=>1862, 10=>38839}
		@disc.set({1=>0}, {1=>100})
		@discid.set(start, length)
		@deps.set('cd-info', true)

		string = FreedbString.new(@deps, @prefs, @disc, @fire, @discid)
		assert_equal(freedb, string.getFreedbString.upcase)
		assert_equal(freedb.split()[0], string.getDiscId.upcase)
	end
	
	# testcase for query 05
	def test_AudioDiscDataTrack
		freedb = "A111490D 13 150 15477 31850 63087 88235 109277 135597 \
157652 173957 191547 205707 231185 275347 4427"
		start = {1=>0, 2=>15327, 3=>31700, 4=>62937, 5=>88085, 6=>109127, 
7=>135447, 8=>157502, 9=>173807, 10=>191397, 11=>205557, 12=>231035, 
13=>275197}
		length = {1=>15327, 2=>16373, 3=>31237, 4=>25148, 5=>21042, 
6=>26320, 7=>22055, 8=>16305, 9=>17590, 10=>14160, 11=>25478, 12=>32762,
13=>56709}
		@disc.set({1=>0}, {1=>100})
		@discid.set(start, length)
		@deps.set('cd-info', true)
		string = FreedbString.new(@deps, @prefs, @disc, @fire, @discid)
		assert_equal(freedb, string.getFreedbString.upcase)
		assert_equal(freedb.split()[0], string.getDiscId.upcase)
	end
end
