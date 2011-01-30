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

require './mocks/FakeOutput.rb'
require './mocks/FakeCleanPrefs.rb'
require './mocks/FakeSavePrefs.rb'
require './mocks/FakeLoadPrefs.rb'
require './mocks/FakeDependency.rb'
require 'rubyripper/preferences/preferences.rb'

# This class tests the settings class
class TC_Preferences < Test::Unit::TestCase
	
	# create some test instances
	def setup
		$stdout, @backup = FakeOutput.new, $stdout
		@load = FakeLoadPrefs.new()
		@save = FakeSavePrefs.new()
		@clean = FakeCleanPrefs.new()
		@deps = FakeDependency.new({'cdrom'=>'testDrive', 
'editor' => 'paper', 'browser' => 'netscape', 'filemanager' => 'explorer'})
		@prefs = Preferences.new(@load, @save, @clean, @deps)
	end

	# when the test is over reset the standard output
	def teardown
		$stdout = @backup
	end

	# let's do some simple tests first
	def test_LoadProperly
		@load.configFound = false
		@load.set({'username'=>'test', 'firstHit'=>true})
		@prefs.loadConfig()

		assert_equal(false, @prefs.isConfigFound)
		assert_equal('test', @prefs.get('username'))
		assert_equal(true, @prefs.get('firstHit'))
		assert_equal('testDrive', @prefs.get('cdrom'))
		assert_equal('paper', @prefs.get('editor'))
		assert_equal('netscape', @prefs.get('browser'))
		assert_equal('explorer', @prefs.get('filemanager'))

		assert_equal('test', @save.prefs['username'])
		assert_equal(true, @save.prefs['firstHit'])

		assert_equal(true, @clean.cleanup)
	end

	# and what if the keys don't exist?
	def test_LoadWithNotExistingKeys
		@load.configFound = true
		@load.set({'crazy'=>true, 'weird'=>false})
		@prefs.loadConfig()

		assert_equal(nil, @prefs.get('crazy'))
		assert_equal(nil, @prefs.get('weird'))
		assert_equal(true, @prefs.isConfigFound)
	end

	# now test if the settings are updated
	def test_SetPreferences
		@load.configFound = true
		@load.set(Hash.new)
		@prefs.loadConfig()
		
		@prefs.set('editor', 'gedit')
		@prefs.set('maxThreads', 5)
		assert_equal(nil, @prefs.set('nuts', true))
		assert_equal('gedit', @prefs.get('editor'))
		assert_equal(5, @prefs.get('maxThreads'))
		assert_equal(nil, @prefs.get('nuts'))
		assert_equal('gedit', @save.prefs['editor'])
	end
end
