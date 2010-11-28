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

require 'rubyripper/disc/scanDiscCdrdao.rb'

# A class to test if the Cd-info is correctly parsed
class TC_ScanDiscCdrdao < Test::Unit::TestCase
	# testcases once loaded
	def setup
		@file001 = File.read(File.join($localdir, 'data/discs/001/cdrdao'))		
		@file002 = File.read(File.join($localdir, 'data/discs/002/cdrdao'))
		@file003 = File.read(File.join($localdir, 'data/discs/003/cdrdao'))
		@file004 = File.read(File.join($localdir, 'data/discs/004/cdrdao'))
		@file005 = File.read(File.join($localdir, 'data/discs/005/cdrdao'))
		@file006 = File.read(File.join($localdir, 'data/discs/006/cdrdao'))
		@disc001 = ScanDiscCdrdao.new($settings, @file001)
		@disc002 = ScanDiscCdrdao.new($settings, @file002)
		@disc003 = ScanDiscCdrdao.new($settings, @file003)
		@disc004 = ScanDiscCdrdao.new($settings, @file004)
		@disc005 = ScanDiscCdrdao.new($settings, @file005)
		@disc006 = ScanDiscCdrdao.new($settings, @file006)
		@failed = ScanDiscCdrdao.new($settings, String.new)
		@allDiscs = [@disc001, @disc002, @disc003, @disc004, @disc005, @disc006]
	end

	# run all tests
	def testSuite
		methodReturnType()
		failed()		
		query001()
		query002()
		query003()
		query004()
		query005()
		query006()
	end

	# test the type of the methods
	def methodReturnType
		@allDiscs.each do |disc|
			assert_kind_of(Array, disc.getLog())
			assert_kind_of(String, disc.status)
			assert_kind_of(Hash, disc.getInfo)
		end
	end

	# test if command failed
	def failed
		assert_equal(_('ERROR: Cdrdao exited unexpectedly.'), @failed.status)
	end

	# test is query001 is parsed (no disc)
	def query001
		assert_equal(_('ERROR: No disc found'), @disc001.status)
	end

	# test if query002 is parsed (invalid parameters)
	def query002
		assert_equal(_('ERROR: Cdrdao doesn\'t recognize the parameters.'), @disc002.status)
	end

	# test if query003 is parsed (no valid disc drive)
	def query003
		assert_equal(_('ERROR: Not a valid cdrom drive'), @disc003.status)
	end

	# test if query004 is parsed (pure audio disc)
	def	query004
		assert_equal(_('ok'), @disc004.status)
		assert_equal(0, @disc004.getInfo('preEmphasis').length)
		assert_equal('CD_DA', @disc004.getInfo('discType'))
		assert_equal(false, @disc004.getInfo('artist'))
		assert_equal(false, @disc004.getInfo('album'))
		assert_equal(0, @disc004.getInfo('trackNames').length)
		assert_equal(0, @disc004.getInfo('varArtists').length)
		assert_equal(false, @disc004.getInfo('silence'))
		assert_equal(0, @disc004.getInfo('dataTracks').length)
		assert_equal(0, @disc004.getInfo('preGap').length)
		assert_equal(0, @disc004.getInfo('preEmphasis').length)
		assert_equal(10, @disc004.getInfo('tracks'))
		assert_equal(_("No pregaps, silences or pre-emphasis detected\n"),@disc004.getLog[0])
	end

	# test if query005 is parsed (audio disc with data track at the end)
	def	query005
		assert_equal(_('ok'), @disc005.status)
		assert_equal(0, @disc005.getInfo('preEmphasis').length)
		assert_equal('CD_DA', @disc005.getInfo('discType'))
		assert_equal(false, @disc005.getInfo('artist'))
		assert_equal(false, @disc005.getInfo('album'))
		assert_equal(0, @disc005.getInfo('trackNames').length)
		assert_equal(0, @disc005.getInfo('varArtists').length)
		assert_equal(false, @disc005.getInfo('silence'))
		assert_equal(0, @disc005.getInfo('dataTracks').length)
		assert_equal(0, @disc005.getInfo('preEmphasis').length)
		assert_equal(12, @disc005.getInfo('tracks'))
		assert_equal(false, @disc005.getLog.empty?)

		{4 => 35, 7 => 32, 10 => 05, 11 => 20}.each do |key, value|
			assert_equal(value, @disc005.getInfo('preGap')[key])
		end
	end

	# test if query006 is parsed (audio disc with cd-text)
	def query006
		assert_equal(_('ok'), @disc006.status)
		assert_equal(0, @disc006.getInfo('preEmphasis').length)
		assert_equal('CD_DA', @disc006.getInfo('discType'))
		assert_equal('SYSTEM OF A DOWN', @disc006.getInfo('artist'))
		assert_equal('STEAL THIS ALBUM!', @disc006.getInfo('album'))
		assert_equal(0, @disc006.getInfo('varArtists').length)
		assert_equal(false, @disc006.getInfo('silence'))
		assert_equal(0, @disc006.getInfo('dataTracks').length)
		assert_equal(0, @disc006.getInfo('preGap').length)
		assert_equal(0, @disc006.getInfo('preEmphasis').length)
		assert_equal(16, @disc006.getInfo('tracks'))
		assert_equal(false, @disc006.getLog.empty?)

		{1=>"CHIC 'N' STEW", 2=>"INNERVISION", 3=>"BUBBLES", 4=>"BOOM!", 
5=>"N\\334GUNS", 6=>"A.D.D.", 7=>"MR. JACK", 8=>"I-E-A-I-A-I-O", 9=>"36", 
10=>"PICTURES", 11=>"HIGHWAY SONG", 12=>"F**K THE SYSTEM", 13=>"EGO BRAIN", 14=>"THETAWAVES", 15=>"ROULETTE", 16=>"STREAMLINE"}.each do |key, value|
			assert_equal(value, @disc006.getInfo('trackNames')[key])
		end
	end
end
