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

require 'rubyripper/disc/scanDiscCdparanoia.rb'

# A class to test the reading of the cdparanoia output
class TC_ScanDiscCdparanoia < Test::Unit::TestCase

	# test if there is no disc
	def test_NoDisc
		file = File.read(File.join($localdir, 'data/discs/001/cdparanoia'))
		instance = ScanDiscCdparanoia.new($deps, $settings, file)

		status = _("No disc found in drive /dev/cdrom.\n\n\
Please put an audio disc in first...")
		assert_equal(status, instance.status)
	end

	# test if wrong parameters are used
	def test_WrongParameters
		file = File.read(File.join($localdir, 'data/discs/002/cdparanoia'))
		instance = ScanDiscCdparanoia.new($deps, $settings, file)
		
		status = _('ERROR: Cdparanoia doesn\'t recognize the parameters.')
		assert_equal(status, instance.status)
		assert(!instance.getInfo('multipleDriveSupport'))
	end
	
	# test if drive is unknown
	def test_DriveUnknown
		file = File.read(File.join($localdir, 'data/discs/003/cdparanoia'))
		instance = ScanDiscCdparanoia.new($deps, $settings, file)
		assert_equal(_('ERROR: drive /dev/cdrom is not found'), instance.status)
	end

	# test pure audio disc
	def	test_PureAudioDisc
		file = File.read(File.join($localdir, 'data/discs/004/cdparanoia'))
		instance = ScanDiscCdparanoia.new($deps, $settings, file)
		assert_equal(10, instance.getInfo('audiotracks'))
		assert_equal("HL-DT-ST DVDRAM GH22NS40 NL01", instance.getInfo('devicename'))
		assert_equal("36:12", instance.getInfo('playtime'))
		assert_equal(162919, instance.getInfo('totalSectors'))
		assert_equal(_('ok'), instance.status)
	
		startSectors = [0, 13209, 36539, 53497, 68172, 81097, 87182, 106732,
122218, 124080]
		startSectors.each_index do |index|
			assert_equal(startSectors[index], instance.getInfo('startSector')[index + 1])
			assert_equal(startSectors[index], instance.getStartSector(index + 1))
		end

		lengthSectors = [13209, 23330, 16958, 14675, 12925, 6085, 19550, 15486,
1862, 38839]
		lengthSectors.each_index do |index|
			assert_equal(lengthSectors[index], instance.getInfo('lengthSector')[index + 1])
			assert_equal(lengthSectors[index], instance.getLengthSector(index + 1))
		end

		lengthText = ['02:56.09', '05:11.05', '03:46.08', '03:15.50', 
'02:52.25', '01:21.10', '04:20.50', '03:26.36', '00:24.62', '08:37.64']
		lengthText.each_index do |index|
			assert_equal(lengthText[index], instance.getInfo('lengthText')[index + 1])
			assert_equal(lengthText[index], instance.getLengthText(index + 1))
		end
	end

	# test for audio disc with a data track at the end
	def	test_AudioDiscWithDataTrack
		file = File.read(File.join($localdir, 'data/discs/005/cdparanoia'))
		instance = ScanDiscCdparanoia.new($deps, $settings, file)
		assert_equal(12, instance.getInfo('audiotracks'))
		assert_equal("HL-DT-ST DVDRAM GH22NS40 NL01", instance.getInfo('devicename'))
		assert_equal("58:37", instance.getInfo('playtime'))
		assert_equal(263797, instance.getInfo('totalSectors'))
		assert_equal(_('ok'), instance.status)
	
		startSectors = [0, 15327, 31700, 62937, 88085, 109127, 135447, 157502, 
			173807, 191397, 205557, 231035]
		startSectors.each_index do |index|
			assert_equal(startSectors[index], instance.getInfo('startSector')[index + 1])
			assert_equal(startSectors[index], instance.getStartSector(index + 1))
		end

		lengthSectors = [15327, 16373, 31237, 25148, 21042, 26320, 22055, 16305,
17590, 14160, 25478, 32762]
		lengthSectors.each_index do |index|
			assert_equal(lengthSectors[index], instance.getInfo('lengthSector')[index + 1])
			assert_equal(lengthSectors[index], instance.getLengthSector(index + 1))
		end

		lengthText = ['03:24.27','03:38.23','06:56.37','05:35.23','04:40.42', 
'05:50.70','04:54.05','03:37.30','03:54.40','03:08.60','05:39.53','07:16.62']
		lengthText.each_index do |index|
			assert_equal(lengthText[index], instance.getInfo('lengthText')[index + 1])
			assert_equal(lengthText[index], instance.getLengthText(index + 1))
		end
	end
end
