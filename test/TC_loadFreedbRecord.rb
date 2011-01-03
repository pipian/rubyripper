#!/usr/bin/env ruby
# coding: utf-8
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

require 'rubyripper/fileAndDir.rb'
require './mocks/FakeFileAndDir.rb'
require 'rubyripper/freedb/loadFreedbRecord.rb'

# A class to test if loadFreedbRecord succesfully finds and loads a local file
class TC_LoadFreedbRecord < Test::Unit::TestCase

	# first set a file ready
	def setup
		@file = FakeFileAndDir.new()
		@load = LoadFreedbRecord.new(@file)
	end

	# test if no files are found
	def test_noFilesFound
		@file.data['glob'] << Array.new
		@load.scan('nonsense')

		assert_equal('noRecords', @load.status)
		assert_equal(String.new, @load.freedbRecord)
	end

	# test if only one file found
	def test_oneFileFound
		@file.data['glob'] << ['/test/ABCDEFGH']
		@file.data['read'] << 'sampleText'
		@load.scan('ABCDEFGH')

		assert_equal('ok', @load.status)
		assert_equal('sampleText', @load.freedbRecord)
		assert_equal('/test/ABCDEFGH', @file.usage['read'][0])	
	end

	# test if two files are found
	def test_twoFilesFound
		@file.data['glob'] << ['/test/jazz/ABCDEFGH', '/test/blues/ABCDEFGH']
		@file.data['read'] << 'sampleText'
		@load.scan('ABCDEFGH')

		assert_equal('ok', @load.status)
		assert_equal('sampleText', @load.freedbRecord)
		assert_equal('/test/jazz/ABCDEFGH', @file.usage['read'][0])	
	end

	# When importing directly in UTF-8 fails, try with ISO-8859-1 encoding
	def test_88591_encoding
		@file.data['glob'] << ['/test/blues/ABCDEFGH']
		@file.data['read'] << "validEncoding"
		@file.data['read'] << "hello red \xE8".force_encoding("UTF-8")

		@load.scan('ABCDEFGH')

		assert_equal('ok', @load.status)
		assert_equal('validEncoding', @load.freedbRecord)
		assert_equal('/test/blues/ABCDEFGH', @file.usage['read'][0])	
	end

	# When importing fails twice, set status to InvalidEncoding
	def test_importing_fails
		@file.data['glob'] << ['/test/blues/ABCDEFGH']
		@file.data['read'] << "hello red \xE8".force_encoding("UTF-8")
		@file.data['read'] << "hello red \xE8".force_encoding("UTF-8")
		@load.scan('ABCDEFGH')

		assert_equal('InvalidEncoding', @load.status)
		assert_equal('', @load.freedbRecord)
		assert_equal('/test/blues/ABCDEFGH', @file.usage['read'][0])	
	end

	# Import a GB18030 file
	def test_GB18030
		@filename = File.expand_path('./data/freedb/GB18030')
		@load = LoadFreedbRecord.new(FileAndDir.new())
		@load.read(@filename)
		assert_equal('UTF-8', @load.freedbRecord.encoding.name)
		assert_equal(true, @load.freedbRecord.valid_encoding?)
		assert_equal('r:GB18030', @load.encoding)
		assert_equal("# xmcd\n#\n# Track frame offsets:\n# 150\n# 17308\n# 38795\n# 61430\n# 80299\n# 98831\n# 119629\n# 137609\n# 155164\n# 174680\n# 193904\n# 212215\n#\n# Disc length: 3123 seconds\n#\n#\n# Revision: 9\n# Processed by: cddbd v1.5.2PL0 Copyright (c) Steve Scherf et al.\n# Submitted via: FreeRIP 2.945 \n#\nDISCID=a70c310c\nDTITLE=周杰伦 / 十一月的萧邦\nDYEAR=2005\nDGENRE=Pop\nTTITLE0=夜曲\nTTITLE1=蓝色风暴\nTTITLE2=发如雪\nTTITLE3=黑色毛衣\nTTITLE4=四面楚歌\nTTITLE5=枫\nTTITLE6=浪漫手机\nTTITLE7=逆鳞\nTTITLE8=麦芽糖\nTTITLE9=珊瑚海\nTTITLE10=飘移\nTTITLE11=一路向北\nEXTD=correct one\nEXTT0=\nEXTT1=\nEXTT2=\nEXTT3=\nEXTT4=\nEXTT5=\nEXTT6=\nEXTT7=\nEXTT8=\nEXTT9=\nEXTT10=\nEXTT11=\nPLAYORDER=\n", @load.freedbRecord)
	end

	# Import a ISO-8859-1 file
	def test_ISO_8859_1
		@filename = File.expand_path('./data/freedb/ISO88591')
		@load = LoadFreedbRecord.new(FileAndDir.new())
		@load.read(@filename)
		assert_equal('UTF-8', @load.freedbRecord.encoding.name)
		assert_equal(true, @load.freedbRecord.valid_encoding?)
		assert_equal('r:ISO-8859-1', @load.encoding)
		assert_equal("# xmcd CD database file\n#\n# Track frame offsets:\n#\t150\n#\t25324\n#\t44858\n#\t76057\n#\n# Disc length: 1374 seconds\n#\n# Revision: 0\n# Processed by: cddbd v1.5.2PL0 Copyright (c) Steve Scherf et al.\n# Submitted via: CDex 1.70beta2\n#\nDISCID=2b055c04\nDTITLE=Tuhonvarjo / Syvyyden Syli\nDYEAR=2010\nDGENRE=Metal\nTTITLE0=Syvyyden Syli\nTTITLE1=Tyhjyys\nTTITLE2=Joutsenen Siivillä\nTTITLE3=Surumarssi\nEXTD= YEAR: 2010\nEXTT0=\nEXTT1=\nEXTT2=\nEXTT3=\nPLAYORDER=\n", @load.freedbRecord)
	end
end
