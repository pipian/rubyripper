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

# load all necessary files
require 'rubyripper/base.rb'

# All classes are designed to have low impact on creation time
# To help the unit testing part, the whole object tree is created
# at the call of createAll in this class. The objects
# can be fetched when necessary with the get function.
# First the leaves are loaded then the higher level objects
# See the classOverviewUmlet to have a visual of the objects
class InstanceHelper

	# setup a Hash to save all classes
	def initialize
		@classes = Hash.new
	end

	# get a specific object
	def get(className)
		if !@classes.key?(className)
			puts "WARNING: #{className} does not exist!"
		end
		return @classes[className]
	end

	# set classes based on the frontend
	def createAll(frontend)
		@classes['frontend'] = frontend
		preferences()
		#metadata()
		#disc()
		#ripping()
		setFrontend()
	end

private

	# load all necessary files and setup preferences objects
	def preferences
		require 'rubyripper/fileAndDir.rb'
		require 'rubyripper/preferences/loadPrefs.rb'
		require 'rubyripper/preferences/savePrefs.rb'
		require 'rubyripper/preferences/cleanPrefs.rb'
		require 'rubyripper/dependency.rb'
		require 'rubyripper/preferences/preferences.rb'

		@classes['fileAndDir'] = FileAndDir.new
		@classes['loadPrefs'] = LoadPrefs.new(get('fileAndDir'))
		@classes['savePrefs'] = SavePrefs.new(get('fileAndDir'))
		@classes['cleanPrefs'] = CleanPrefs.new(get('fileAndDir'))
		@classes['dependency'] = Dependency.new()
		@classes['preferences'] = Preferences.new(get('loadPrefs'),
get('savePrefs'), get('cleanPrefs'), get('dependency'))
	end

	# load all necessary files and setup metadata objects
	# do this before the disc object, because the metadata
	# object is passed to the disc object
	def metadata
		require 'rubyripper/freedb/loadFreedbRecord.rb'
		require 'rubyripper/freedb/saveFreedbRecord.rb'
		require 'rubyripper/freedb/cgiHttpHandler.rb'
		require 'rubyripper/freedb/getFreedbRecord.rb'

		require 'rubyripper/freedb/freedbRecordParser.rb'
		require 'rubyripper/metadata.rb'

		@classes['loadFreedbRecord'] = LoadFreedbRecord.new(get('fileAndDir'))
		@classes['saveFreedbRecord'] = SaveFreedbRecord.new(get('fileAndDir'))
		@classes['cgiHttpHandler'] = CgiHttpHandler.new(get('preferences'))
		@classes['getFreedbRecord'] = GetFreedbRecord.new(get('preferences'), 
get('cgiHttpHandler'))
		
		@classes['freedbRecordParser'] = FreedbRecordParser.new()

		@classes['metadata'] = Metadata.new(get('loadFreedbRecord'), 
get('saveFreedbRecord'), get('getFreedbRecord'), get('freedbRecordParser'))
	end

	# load all necessary files and setup disc objects
	def disc
		require 'rubyripper/fireCommand.rb'
		require 'rubyripper/permissionDrive.rb'
		require 'rubyripper/disc/scanDiscCdparanoia.rb'
		require 'rubyripper/disc/cuesheet.rb'
		require 'rubyripper/disc/scanDiscCdrdao.rb'
		require 'rubyripper/disc/scanDiscCdinfo.rb'
		require 'rubyripper/freedb/freedbString.rb'
		require 'rubyripper/disc.rb'

		@classes['fireCommand'] = FireCommand.new(get('dependency'))
		@classes['permissionDrive'] = PermissionDrive.new()
		@classes['scanDiscCdparanoia'] = ScanDiscCdparanoia.new(
get('preferences'), get('fireCommand'), get('permissionDrive'))

		@classes['cuesheet'] = Cuesheet.new()
		@classes['scanDiscCrdao'] = ScanDiscCdrdao.new(get('preferences'),
get('fireCommand'), get('cuesheet'))

		@classes['scanDiscCdinfo'] = ScanDiscCdinfo.new(get('preferences'),
get('fireCommand'))

		@classes['freedbString'] = FreedbString.new(get('dependency'),
get('preferences'), get('scanDiscCdparanoia'), get('fireCommand'),
get('scanDiscCdinfo'))

		@classes['disc'] = Disc.new(get('scanDiscCdparanoia'),
get('metadata'), get('scanDiscCdrdao'), get('freedbString'))
	end

	# Load all objects for the actual ripping
	def ripping
		#TODO
#		@rubyripper = Rubyripper.new(FileManager.new, Ripping.new, 
#Encodings.new, Logging.new)
	end

	def setFrontend
		if !@classes['frontend'].respond_to?('name')
			puts "WARNING: 'name' method not found in instanceHelper.rb"
		elsif @classes['frontend'].name == 'cli'
			startupCli()
		elsif @classes['frontend'].name == 'gtk2'
			startupGtk2()
		else
			puts "WARNING: #{@classes['frontend'].name} is not defined \
in instanceHelper.rb"
		end
	end

	# Load all objects for the Cli interface
	def startupCli
		require 'rubyripper/cli/cliGetAnswer.rb'
		require 'rubyripper/cli/cliPreferences.rb'
		require 'rubyripper/cli/cliMetadata.rb'
		require 'rubyripper/cli/cliTracklist.rb'

		@classes['cliGetBool'] = CliGetBool.new()
		@classes['cliGetInt'] = CliGetInt.new()
		@classes['cliGetString'] = CliGetString.new()
		@classes['cliPreferences'] = CliPreferences.new(get('preferences'),
get('cliGetInt'), get('cliGetBool'), get('cliGetString'))

# TODO		@classes['cliMetadata'] = CliMetadata.new(get('disc'), 
# TODO get('preferences'), get('cliGetBool'), get('cliGetInt'), get('cliGetString'))
		
# TODO		@classes['cliTracklist'] = CliTracklist.new(get('preferences'), 
# TODO get('disc'))
	end

	# Load all objects for the Gtk2 interface
	def startupGtk2
		#TODO
	end
end
