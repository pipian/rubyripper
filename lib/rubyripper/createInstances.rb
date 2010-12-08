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

# This class just creates the whole object tree
# This bottom-up design is recommended for testing purposes
# For this to work, none of the classes can set all kind of actions
class CreateInstances

	# create instances for scanning the disc and other preparations
	def initialize
		createGeneric()
		createDisc()
		createMetadata()
	end

	# create instances for the ripping process
	def createRipper(gui)
		@rubyripper = Rubyripper.new(FileManager.new, Ripping.new, 
Encodings.new, Logging.new)
	end

private
	# create all generic classes first
	def createGeneric
		@dependency = Dependency.new
		@preferences = Preferences.new(LoadPrefs.new, SavePrefs.new, 
CleanPrefs.new, @dependency)
		@fireCommand = FireCommand.new(@dependency)
	end

	# create the disc except for metadata
	def createDisc
		@scanDiscCdinfo = ScanDiscCdinfo.new(@preferences, @fireCommand)

		@scanDiscCdparanoia = ScanDiscCdparanoia.new(@preferences, @fireCommmand 
PermissionDrive.new(@dependency))

		@scanDiscCdrdao = ScanDiscCdrdao.new(@preferences, @fireCommand, Cuesheet.new)
		@disc = Disc.new(@
	end

	# make an instance of metadata
	def createMetadata
		@freedbString = FreedbString.new(@preferences, @fireCommand, 
@scanDiscCdparanoia, @scanDiscCdinfo)

		@metadata = Metadata.new(LoadFreedbRecord.new, SaveFreedbRecord.new,
GetFreedbRecord.new, CgiHttpHandler.new(@preferences), FreedbRecordParser.new,
@freedbString)

		@cuesheet = Cuesheet.new(@preferences, @scanDiscCdrdao)
	end


end
