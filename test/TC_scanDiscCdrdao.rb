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
require './mocks/FakeFireCommand.rb'
require 'rubyripper/disc/scanDiscCdrdao.rb'

# A class to test if the Cd-info is correctly parsed
class TC_ScanDiscCdrdao < Test::Unit::TestCase

	def setup
		settings = {'verbose' => false, 'debug' => false, 'cdrom' => 'test'}
		@prefs = FakePreferences.new(settings)
		@fire = FakeFireCommand.new
		@cdrdao = ScanDiscCdrdao.new(@prefs, @fire)
	end

	# test if command failed
	def test_Failed
		@fire.file = 'This is a test'
		@fire.status = 'not good'
		@cdrdao.scan()
		assert_equal(_('ERROR: Cdrdao exited unexpectedly.'), @cdrdao.status)
	end

	# test is query001 is parsed (no disc)
	def test_NoDisc
		@fire.file = File.read(File.join($localdir, 'data/discs/001/cdrdao'))
		@cdrdao.scan()
		assert_equal(_('ERROR: No disc found'), @cdrdao.status)
	end

	# test if query002 is parsed (invalid parameters)
	def test_InvalidParameters
		@fire.file = File.read(File.join($localdir, 'data/discs/002/cdrdao'))
		@cdrdao.scan()
		assert_equal("cdrdao read-toc --device test \"/tmp/temp_test.toc\" 2>&1", @fire.last)
		assert_equal(_('ERROR: Cdrdao doesn\'t recognize the parameters.'), @cdrdao.status)
	end

	# test if query003 is parsed (no valid disc drive)
	def test_NoValidDiscDrive
		@fire.file = File.read(File.join($localdir, 'data/discs/003/cdrdao'))
		@cdrdao.scan()
		assert_equal(_('ERROR: Not a valid cdrom drive'), @cdrdao.status)
	end

	# test if query004 is parsed (pure audio disc)
	def	test_AudioDisc
		@fire.file = File.read(File.join($localdir, 'data/discs/004/cdrdao'))
		@cdrdao.scan()
		assert_equal('ok', @cdrdao.status)
		assert_equal(0, @cdrdao.get('preEmphasis').length)
		assert_equal('CD_DA', @cdrdao.get('discType'))
		assert_equal(false, @cdrdao.get('artist'))
		assert_equal(false, @cdrdao.get('album'))
		assert_equal(0, @cdrdao.get('trackNames').length)
		assert_equal(0, @cdrdao.get('varArtists').length)
		assert_equal(false, @cdrdao.get('silence'))
		assert_equal(0, @cdrdao.get('dataTracks').length)
		assert_equal(0, @cdrdao.get('preGap').length)
		assert_equal(0, @cdrdao.get('preEmphasis').length)
		assert_equal(10, @cdrdao.get('tracks'))
		assert_equal(_("No pregaps, silences or pre-emphasis detected\n"),@cdrdao.getLog[0])
	end

	# test if query005 is parsed (audio disc with data track at the end)
	def	test_AudioDiscWithDataTrack
		@fire.file = File.read(File.join($localdir, 'data/discs/005/cdrdao'))
		@cdrdao.scan()
		assert_equal('ok', @cdrdao.status)
		assert_equal(0, @cdrdao.get('preEmphasis').length)
		assert_equal('CD_DA', @cdrdao.get('discType'))
		assert_equal(false, @cdrdao.get('artist'))
		assert_equal(false, @cdrdao.get('album'))
		assert_equal(0, @cdrdao.get('trackNames').length)
		assert_equal(0, @cdrdao.get('varArtists').length)
		assert_equal(false, @cdrdao.get('silence'))
		assert_equal(0, @cdrdao.get('dataTracks').length)
		assert_equal(0, @cdrdao.get('preEmphasis').length)
		assert_equal(12, @cdrdao.get('tracks'))
		assert_equal(false, @cdrdao.getLog.empty?)

		{4 => 35, 7 => 32, 10 => 05, 11 => 20}.each do |key, value|
			assert_equal(value, @cdrdao.get('preGap')[key])
		end
	end

	# test if query006 is parsed (audio disc with cd-text)
	def test_AudioDiscCdText
		@fire.file = File.read(File.join($localdir, 'data/discs/006/cdrdao'))
		@cdrdao.scan()
		assert_equal('ok', @cdrdao.status)
		assert_equal(0, @cdrdao.get('preEmphasis').length)
		assert_equal('CD_DA', @cdrdao.get('discType'))
		assert_equal('SYSTEM OF A DOWN', @cdrdao.get('artist'))
		assert_equal('STEAL THIS ALBUM!', @cdrdao.get('album'))
		assert_equal(0, @cdrdao.get('varArtists').length)
		assert_equal(false, @cdrdao.get('silence'))
		assert_equal(0, @cdrdao.get('dataTracks').length)
		assert_equal(0, @cdrdao.get('preGap').length)
		assert_equal(0, @cdrdao.get('preEmphasis').length)
		assert_equal(16, @cdrdao.get('tracks'))
		assert_equal(false, @cdrdao.getLog.empty?)

		{1=>"CHIC 'N' STEW", 2=>"INNERVISION", 3=>"BUBBLES", 4=>"BOOM!", 
5=>"N\\334GUNS", 6=>"A.D.D.", 7=>"MR. JACK", 8=>"I-E-A-I-A-I-O", 9=>"36", 
10=>"PICTURES", 11=>"HIGHWAY SONG", 12=>"F**K THE SYSTEM", 13=>"EGO BRAIN", 14=>"THETAWAVES", 15=>"ROULETTE", 16=>"STREAMLINE"}.each do |key, value|
			assert_equal(value, @cdrdao.get('trackNames')[key])
		end
	end
end
