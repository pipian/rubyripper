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
		return @classes[className]
	end

	# set classes based on the frontend
	def createAll(frontend)
		preferences()
		metadata()
		disc()

		if frontend == 'cli'
			startupCli()
		elsif frontend == 'gtk2'
			startupGtk2()
		end
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
		@classes['dependency'] = Dependency.new
		@classes['preferences'] = Preferences.new(get('loadPrefs'),
get('savePrefs'), get('cleanPrefs'), get('dependency'))
	end

	# load all necessary files and setup metadata objects
	# do this before the disc object, because the metadata
	# object is passed to the disc object
	def metadata
		require 'rubyripper/freedb/loadFreedbRecord.rb'
		require 'rubyripper/freedb/freedbRecordParser.rb'
		require 'rubyripper/metadata.rb'

		#TODO @classes['metadata'] = 
		#@metadata = Metadata.new(LoadFreedbRecord.new, SaveFreedbRecord.new,
#GetFreedbRecord.new, CgiHttpHandler.new(@preferences), FreedbRecordParser.new,
#@freedbString)
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

	# Load all objects for the Gtk2 interface
	def startupGtk2
	end

	# Load all objects for the Cli interface
	def startupCli
		#require 'rubyripper/dependency.rb'
		#require 'rubyripper/cli/cliSettings.rb'
		#require 'rubyripper/cli/cliMetadata.rb'
		#require 'rubyripper/cli/cliGetAnswer.rb'
# TODO require 'rubyripper/cli/cliTracklist.rb'
		# verify if all dependencies are found
#		@objects['deps'] = Dependency.new(verbose=true, runtime=true)
	
		# save all answer machines in a Hash and pass them (better for testing)
#		@objects['getString'] = GetString.new
#		@objects['getInt'] = GetInt.new
#		@objects['getBool'] = GetBool.new

		# set the gui
#		@objects['gui'] = self

		# get the settings
#		@objects['settingsCli'] = CliSettings.new(@objects)
#		@objects['disc'] = Disc.new(@objects)

		# show the discinfo
#		@objects['discCli'] = CliMetadata.new(@objects)
	end

	# create instances for the ripping process
	#def createRipper(gui)
	#	@classes['filemanager'] = FileManager.new()
	#	@rubyripper = Rubyripper.new(FileManager.new, Ripping.new, 
#Encodings.new, Logging.new)
#	end
end
