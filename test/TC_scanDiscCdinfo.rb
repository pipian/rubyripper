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

require 'rubyripper/disc/scanDiscCdinfo.rb'

# A class to test if the Cd-info is correctly parsed
class TC_ScanDiscCdinfo < Test::Unit::TestCase
	# testcases once loaded
	def setup
		@file001 = File.read(File.join($localdir, 'data/discs/001/cd-info'))		
		@file002 = File.read(File.join($localdir, 'data/discs/002/cd-info'))
		@file003 = File.read(File.join($localdir, 'data/discs/003/cd-info'))
		@file004 = File.read(File.join($localdir, 'data/discs/004/cd-info'))
		@file005 = File.read(File.join($localdir, 'data/discs/005/cd-info'))
		@inst001 = ScanDiscCdinfo.new('/dev/cdrom', @file001)
		@inst002 = ScanDiscCdinfo.new('/dev/cdrom', @file002)
		@inst003 = ScanDiscCdinfo.new('/dev/cdrom', @file003)
		@inst004 = ScanDiscCdinfo.new('/dev/cdrom', @file004)
		@inst005 = ScanDiscCdinfo.new('/dev/dvdrom', @file005)
	end

	# run all tests, all functions that start with test are loaded
	def testSuite
		instance001()
		instance002()
		instance003()
		instance004()
		instance005()
	end

	# test is inst001 is parsed (no disc)
	def instance001
		assert_equal(_('ERROR: No disc found'), @inst001.status)
	end

	# test if inst002 is parsed (invalid parameters)
	def instance002
		assert_equal(_('ERROR: invalid parameters for cd-info'), @inst002.status)
	end

	# test if inst003 is parsed (no valid disc drive)
	def instance003
		assert_equal(_('ERROR: Not a valid cdrom drive'), @inst003.status)
	end

	# test if inst004 is parsed (pure audio disc)
	def	instance004
		assert_equal(10, @inst004.getInfo('audiotracks'))
		assert_equal("HL-DT-ST DVDRAM GH22NS40 NL01", @inst004.getInfo('devicename'))
		assert_equal("36:12", @inst004.getInfo('playtime'))
		assert_equal(162919, @inst004.getInfo('totalSectors'))
		assert_equal(_('ok'), @inst004.status)
	
		startSectors = [0, 13209, 36539, 53497, 68172, 81097, 87182, 106732, 122218, 124080]
		startSectors.each_index do |index|
			assert_equal(startSectors[index], @inst004.getInfo('startSector')[index + 1])
		end

		lengthSectors = [13209, 23330, 16958, 14675, 12925, 6085, 19550, 15486, 1862, 38839]
		lengthSectors.each_index do |index|
			assert_equal(lengthSectors[index], @inst004.getInfo('lengthSector')[index + 1])
		end

		lengthText = ['02:56.09', '05:11.05', '03:46.08', '03:15.50', '02:52.25', 
		'01:21.10', '04:20.50', '03:26.36', '00:24.62', '08:37.64']
		lengthText.each_index do |index|
			assert_equal(lengthText[index], @inst004.getInfo('lengthText')[index + 1])
		end
	end

	# test if inst005 is parsed (audio disc with data track at the end)
	def	instance005
		assert_equal(13, @inst005.getInfo('tracks'))
		assert_equal("HL-DT-ST DVDRAM GH22NS40 NL01", @inst005.getInfo('devicename'))
		assert_equal("73:45", @inst005.getInfo('playtime'))
		assert_equal(331906, @inst005.getInfo('totalSectors'))
		assert_equal(_('ok'), @inst005.status)
	
		startSectors = [0, 15327, 31700, 62937, 88085, 109127, 135447, 157502, 
			173807, 191397, 205557, 231035, 275197]
		startSectors.each_index do |index|
			assert_equal(startSectors[index], @inst005.getInfo('startSector')[index + 1])
		end

		lengthSectors = [15327, 16373, 31237, 25148, 21042, 26320, 22055, 16305,
			17590, 14160, 25478, 44162, 56709]
		lengthSectors.each_index do |index|
			assert_equal(lengthSectors[index], @inst005.getInfo('lengthSector')[index + 1])
		end

		lengthText = ['03:24.27', '03:38.23', '06:56.37', '05:35.23', '04:40.42', 
			'05:50.70', '04:54.05', '03:37.30', '03:54.40', '03:08.60', 
			'05:39.53', '09:48.62']
		lengthText.each_index do |index|
			assert_equal(lengthText[index], @inst005.getInfo('lengthText')[index + 1])
		end
	end
end
