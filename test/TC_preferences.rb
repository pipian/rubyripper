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

require 'rubyripper/settings.rb'
require 'rubyripper/dependency.rb'

# This class tests the settings class
class TC_Settings < Test::Unit::TestCase
	
	# create some test instances
	def setup
		@failed = File.join($localdir, 'data/settings/doesNotExist')
		@file001 = File.join($localdir, 'data/settings/settings001')
		@file002 = File.join($localdir, 'data/settings/settings002')
		@file003 = File.join($localdir, 'data/settings/settings003')
		
		@instFailed = Settings.new($objects, @failed)
		@inst001 = Settings.new($objects, @file001)
		@inst002 = Settings.new($objects, @file002)
		@inst003 = Settings.new($objects, @file003)

		@boolKeys = ["flac", "vorbis", "wav", "other", 'mp3', "playlist", 
"verbose", "debug", "eject", 'ripHiddenAudio', "firstHit", "freedb", "noLog", 
"createCue", "image", 'gainTagsOnly', 'noSpaces', 'noCapitals']

		@textKeys = ["settingsFlac", "settingsVorbis", "settingsMp3", 
"settingsOther", "cdrom", "rippersettings", 'basedir', 'namingNormal',
'basedir', 'namingVarious', 'namingImage', "site", "username", "hostname", 
"editor", "filemanager", "browser", 'normalizer', 'gain', 'preGaps', 'preEmphasis']

		@numberKeys = ["offset", "maxThreads", "maxTries", 
'minLengthHiddenTrack', "reqMatchesErrors", "reqMatchesAll"]

		@allKeys = @boolKeys + @textKeys + @numberKeys
	end

	# load them all at once to prevent the setup penalty
	def testSuite
		if_failed()
		instance001()
		instance002()
		instance003()
	end

	# defaul test for each instance
	def verifyAllKeys(instance, test)
		@allKeys.each do |key|
			assert(instance.getSettings().has_key?(key), "#{test}: #{key} is missing")
		end

		assert_equal(@allKeys.length, instance.getSettings().length)
	end

	# test when the input app has failed (no valid inputfile)
	def if_failed
		assert(!@instFailed.isConfigFound)

		# the settings should be set from the defaults
		verifyAllKeys(@instFailed, 'if_failed')
	end

	# test if inst001 passes (all boolean values true)
	def instance001
		assert(@inst001.isConfigFound)
		verifyAllKeys(@inst001, 'instance001')

		@boolKeys.each do |key|
			assert_equal(true, @inst001.getSettings()[key], "#{key} must be true")
		end

		# test the save function
		settingsHash = Hash.new
		@boolKeys.each{|key| settingsHash[key] = false}
		@inst001.save(settingsHash, true)
		
		@boolKeys.each do |key|
			assert_equal(false, @inst001.getSettings()[key], "#{key} must be false")
		end
	end

	# test if inst002 passes (all boolean values false, all text = 'test', 
	# all numbers = 1001)
	def	instance002
		assert(@inst002.isConfigFound)
		verifyAllKeys(@inst002, 'instance002')

		@boolKeys.each do |key|
			assert_equal(false, @inst002.getSettings()[key], "#{key} must be false")
		end

		@textKeys.each do |key|
			assert_equal('test', @inst002.getSettings()[key], "#{key} must be 'test'")
		end

		@numberKeys.each do |key|
			assert_equal(1, @inst002.getSettings()[key], "#{key} must be 1")
		end

		# test the save function
		settingsHash = Hash.new
		@boolKeys.each{|key| settingsHash[key] = true}
		@inst002.save(settingsHash, true)
		
		@boolKeys.each do |key|
			assert_equal(true, @inst002.getSettings()[key], "#{key} must be true")
		end
	end

	# test inst003 passes (1 nonsense key)
	def	instance003
		assert_equal(true, @inst003.isConfigFound)
		verifyAllKeys(@inst003, 'instance003')

		assert_equal(false, @inst003.getSettings.key?('testIllegalSetting'))
	end
end
