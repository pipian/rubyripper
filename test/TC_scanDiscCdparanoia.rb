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
require './mocks/FakePermissionDrive.rb'
require 'rubyripper/disc/scanDiscCdparanoia.rb'

# A class to test the reading of the cdparanoia output
class TC_ScanDiscCdparanoia < Test::Unit::TestCase

	def setup
		settings = {'cdrom' => 'testDrive', 'ripHiddenAudio' => true, 'minLengthHiddenTrack' => 2}
		@prefs = FakePreferences.new(settings)
		@fire = FakeFireCommand.new
		@perm = FakePermissionDrive.new
		@disc = ScanDiscCdparanoia.new(@prefs, @fire, @perm)
	end

	# test if there is no disc
	def test_NoDisc
		@fire.add(File.read(File.join($localdir, 'data/discs/001/cdparanoia')))
		@disc.scan()

		assert_equal(_("No disc found in drive testDrive.\n\nPlease put an \
audio disc in first..."), @disc.status)
	end

	# test if wrong parameters are used
	def test_WrongParameters
		@fire.add(File.read(File.join($localdir, 'data/discs/002/cdparanoia')))
		@fire.add(File.read(File.join($localdir, 'data/discs/002/cdparanoia')))
		@disc.scan()
		
		assert_equal(_('ERROR: Cdparanoia doesn\'t recognize the parameters.'),
@disc.status)
		assert_equal(false, @disc.get('multipleDriveSupport'))
	end
	
	# test if drive is unknown
	def test_DriveUnknown
		@fire.add(File.read(File.join($localdir, 'data/discs/003/cdparanoia')))
		@disc.scan()
		assert_equal(_('ERROR: drive testDrive is not found'), @disc.status)
	end

	# test pure audio disc
	def	test_PureAudioDisc
		@fire.add(File.read(File.join($localdir, 'data/discs/004/cdparanoia')))
		@disc.scan()
		assert_equal(10, @disc.get('audiotracks'))
		assert_equal("HL-DT-ST DVDRAM GH22NS40 NL01", @disc.get('devicename'))
		assert_equal("36:12", @disc.get('playtime'))
		assert_equal(162919, @disc.get('totalSectors'))
		assert_equal(_('ok'), @disc.status)
	
		startSectors = [0, 13209, 36539, 53497, 68172, 81097, 87182, 106732,
122218, 124080]
		startSectors.each_index do |index|
			assert_equal(startSectors[index], @disc.get('startSector')[index + 1])
			assert_equal(startSectors[index], @disc.getStartSector(index + 1))
		end

		lengthSectors = [13209, 23330, 16958, 14675, 12925, 6085, 19550, 15486,
1862, 38839]
		lengthSectors.each_index do |index|
			assert_equal(lengthSectors[index], @disc.get('lengthSector')[index + 1])
			assert_equal(lengthSectors[index], @disc.getLengthSector(index + 1))
		end

		lengthText = ['02:56.09', '05:11.05', '03:46.08', '03:15.50', 
'02:52.25', '01:21.10', '04:20.50', '03:26.36', '00:24.62', '08:37.64']
		lengthText.each_index do |index|
			assert_equal(lengthText[index], @disc.get('lengthText')[index + 1])
			assert_equal(lengthText[index], @disc.getLengthText(index + 1))
		end
	end

	# test for audio disc with a data track at the end
	def	test_AudioDiscWithDataTrack
		@fire.add(File.read(File.join($localdir, 'data/discs/005/cdparanoia')))
		@disc.scan()
		assert_equal(12, @disc.get('audiotracks'))
		assert_equal("HL-DT-ST DVDRAM GH22NS40 NL01", @disc.get('devicename'))
		assert_equal("58:37", @disc.get('playtime'))
		assert_equal(263797, @disc.get('totalSectors'))
		assert_equal(_('ok'), @disc.status)
	
		startSectors = [0, 15327, 31700, 62937, 88085, 109127, 135447, 157502, 
			173807, 191397, 205557, 231035]
		startSectors.each_index do |index|
			assert_equal(startSectors[index], @disc.get('startSector')[index + 1])
			assert_equal(startSectors[index], @disc.getStartSector(index + 1))
		end

		lengthSectors = [15327, 16373, 31237, 25148, 21042, 26320, 22055, 16305,
17590, 14160, 25478, 32762]
		lengthSectors.each_index do |index|
			assert_equal(lengthSectors[index], @disc.get('lengthSector')[index + 1])
			assert_equal(lengthSectors[index], @disc.getLengthSector(index + 1))
		end

		lengthText = ['03:24.27','03:38.23','06:56.37','05:35.23','04:40.42', 
'05:50.70','04:54.05','03:37.30','03:54.40','03:08.60','05:39.53','07:16.62']
		lengthText.each_index do |index|
			assert_equal(lengthText[index], @disc.get('lengthText')[index + 1])
			assert_equal(lengthText[index], @disc.getLengthText(index + 1))
		end
	end
end
