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

require 'rubyripper/disc/discHelper.rb'

# A class to test the quickscan of a disc
# The quickscan makes use of a cdparanoia command

class TC_QuickScanDisc < Test::Unit::TestCase
	# set up the example files
	def setup
		@query_01 = File.read(File.join($localdir, 'data/cdparanoia/query_01'))
		@query_02 = File.read(File.join($localdir, 'data/cdparanoia/query_02'))
		@query_03 = File.read(File.join($localdir, 'data/cdparanoia/query_03'))
		@query_04 = File.read(File.join($localdir, 'data/cdparanoia/query_04'))
		
		@a = QuickScanDisc.new($settings, @a_gui = FakeGui.new, $deps, 'ab', @query_01)
		@b = QuickScanDisc.new($settings, @b_gui = FakeGui.new, $deps, '', @query_02)
		@c = QuickScanDisc.new($settings, @c_gui = FakeGui.new, $deps, '', @query_03)
		@d = QuickScanDisc.new($settings, @c_gui = FakeGui.new, $deps, '', @query_04)
	end
	
	# run multiple tests at once to prevent the setup penalty
	def testSuite
		methodExist()
		methodReturnType()
		query_01()
		query_02()
		query_03()
		query_04()
	end
	
	# test the existance of the method
	def methodExist
		assert_respond_to(@c, :cdrom)
		assert_respond_to(@c, :multipleDriveSupport)
		assert_respond_to(@c, :audiotracks)
		assert_respond_to(@c, :devicename)
		assert_respond_to(@c, :playtime)
		assert_respond_to(@c, :freedbString)
		assert_respond_to(@c, :totalSectors)
		assert_respond_to(@c, :freedb)
		assert_respond_to(@c, :error)
		assert_respond_to(@c, :discId)
		assert_respond_to(@c, :toc)
		assert_respond_to(@c, :tocStarted)
		assert_respond_to(@c, :tocFinished)
		assert_respond_to(@c, :getStartSector)
		assert_respond_to(@c, :getLengthSector)
		assert_respond_to(@c, :getLengthText)
		assert_respond_to(@c, :getFileSize)
		assert_respond_to(@c, :getFreedbInfo)
	end

	# test the type of the methods
	def methodReturnType
		assert_kind_of(String, @c.cdrom)
		assert_kind_of(Boolean, @c.multipleDriveSupport)
		assert_kind_of(Fixnum, @c.audiotracks)
		assert_kind_of(String, @c.devicename)
		assert_kind_of(String, @c.playtime)
		assert_kind_of(String, @c.freedbString)
		assert_kind_of(String, @c.discId)
		assert_kind_of(Fixnum, @c.totalSectors)
		assert_kind_of(String, @c.error)
	end

	# test if query_01 is parsed (no disc)
	def query_01
		assert_equal(true, @a.error.length > 0)
		assert_equal(0, @a.audiotracks)
	end

	# test if query_02 is parsed (invalid parameters)
	def	query_02
		assert_equal(true, @b.error.length > 0)
		assert_equal(0, @b.audiotracks)
	end

	# test if query_03 is parsed (pure audio disc)
	def	query_03
		assert_equal(true, @c.multipleDriveSupport)
		assert_equal(10, @c.audiotracks)
		assert_equal("HL-DT-ST DVDRAM GH22NS40 NL01", @c.devicename)
		assert_equal("36:12", @c.playtime)
		assert_equal(162919, @c.totalSectors)
		assert_equal('', @c.error)
	
		startSectors = [0, 13209, 36539, 53497, 68172, 81097, 87182, 106732, 122218, 124080]
		startSectors.each_index do |index|
			assert_equal(startSectors[index], @c.getStartSector(index + 1))
		end

		lengthSectors = [13209, 23330, 16958, 14675, 12925, 6085, 19550, 15486, 1862, 38839]
		lengthSectors.each_index do |index|
			assert_equal(lengthSectors[index], @c.getLengthSector(index + 1))		
		end

		lengthText = ['02:56.09', '05:11.05', '03:46.08', '03:15.50', '02:52.25', 
		'01:21.10', '04:20.50', '03:26.36', '00:24.62', '08:37.64']
		lengthText.each_index do |index|
			assert_equal(lengthText[index], @c.getLengthText(index + 1))
		end
	end

	# test if query_04 is parsed (audio disc with data track at the end)
	# Notice this doesn't make any difference for the Cdparanoia output
	def	query_04
		assert_equal(true, @d.multipleDriveSupport)
		assert_equal(12, @d.audiotracks)
		assert_equal("HL-DT-ST DVDRAM GH22NS40 NL01", @d.devicename)
		assert_equal("58:37", @d.playtime)
		assert_equal(263797, @d.totalSectors)
		assert_equal('', @d.error)
	
		startSectors = [0, 15327, 31700, 62937, 88085, 109127, 135447, 157502, 
			173807, 191397, 205557, 231035]
		startSectors.each_index do |index|
			assert_equal(startSectors[index], @d.getStartSector(index + 1))
		end

		lengthSectors = [15327, 16373, 31237, 25148, 21042, 26320, 22055, 16305,
			17590, 14160, 25478, 32762]
		lengthSectors.each_index do |index|
			assert_equal(lengthSectors[index], @d.getLengthSector(index + 1))		
		end

		lengthText = ['03:24.27', '03:38.23', '06:56.37', '05:35.23', '04:40.42', 
			'05:50.70', '04:54.05', '03:37.30', '03:54.40', '03:08.60', 
			'05:39.53', '07:16.62']
		lengthText.each_index do |index|
			assert_equal(lengthText[index], @d.getLengthText(index + 1))
		end
	end
end
