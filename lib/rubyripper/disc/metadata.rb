#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/freedb/freedbString.rb'
require 'rubyripper/freedb/getFreedbRecord.rb'

# This class is responsible for getting all metadata of the disc and tracks
class Metadata

	# * deps = instance of Dependency class
	# * settings = hash with all settings
	# * disc = instance of ScanDiscCdparanoia
	def initialize(deps, settings, disc)
		@deps = deps
		@settings = settings
		checkArguments()
		
		# store all metadata into a hash
		@metadata = Hash.new()		
		setDefaultTags()
		getFreedbString()

		# try to retrieve local metadata first
		findLocalMetadata()
	end

	# return a string with the artist
	def artist ; return getInfo('artist') ; end

	# return a string with the album
	def album ; return getInfo('album') ; end

	# return a string with the year
	def year ; return getInfo('year') ;	end

	# return a string with the genre
	def genre ; return getInfo('genre') ; end

	# return an array of strings with all tracknames
	def tracklist ; return getInfo('tracklist') ; end

private
	
	# return the key of if not found the default
	def getInfo(key, default=false)
		if @metadata.key?(key)
			return @metadata[key]
		else
			return default
		end
	end

	# check the parameters
	def checkArguments
		unless @deps.class == Dependency
			raise ArgumentError, "deps parameter must be an instance of Dependency"
		end
		unless @settings.class == String
			raise ArgumentError, "cdrom parameter must be a string"
		end
		unless @disc.class == ScanDiscCdparanoia
			raise ArgumentError, "disc must be an instance of ScanDiscCdparanoia"
		end
	end

	# before doing any attempts at getting extra metadata set the defaults
	def setDefaultTags
		@metadata['artist'] = _('Unknown')
		@metadata['album'] = _('Unknown')
		@metadata['genre'] = _('Unknown')
		@metadata['year'] = '0'

		@metadata['tracklist'] = Array.new
		(1..@disc.getInfo('audiotracks').each do |track|
			@metadata['tracklist'] << _("Track %s") % [track]
		end
	end

	# read the freedb string from the helper class
	def getFreedbString
		freedbHelper = FreedbString.new(@deps, @cdrom, getDisc('startSector'),
getDisc('lengthSector'))
		@freedbString = freedbHelper.getFreedbString()
		@discId = freedbHelper.getDiscId()
		if not findLocalMetadata
			@freedb = getFreedbRecord.new(@freedbString, @settings)
		end
	end

	# search local environment for cached information, return true if success
	def findLocalMetadata
		
	end

#	def searchMetadata
# 		if File.exist?(@settings['freedbCache'])
#			@metadataFile = YAML.load(File.open(@settings['freedbCache']))
#			#in case it got corrupted somehow
#			@metadataFile = Hash.new if @metadataFile.class != Hash
#		else
#			@metadataFile = Hash.new
#		end
#
#		if @disc.freedbString != @disc.oldFreedbString # Scanning the same disc will always result in an new freedb fetch.
#			if @metadataFile.has_key?(@disc.freedbString) || findLocalMetadata #is the Metadata somewhere local?
#				if @metadataFile.has_key?(@disc.freedbString)
#					@rawResponse = @metadataFile[@disc.freedbString]
#				end
#				@tracklist.clear()
#				handleResponse()
#				@status = true # Give the signal that we're finished
#				return true
#			end
#		end
#
#		if @verbose ; puts "preparing to contact freedb server" end
#		handshake()
#	end
#
#	def findLocalMetadata
#		if File.directory?(dir = File.join(ENV['HOME'], '.cddb'))
#			Dir.foreach(dir) do |subdir|
#				if subdir == '.' || subdir == '..' || !File.directory?(File.join(dir, subdir)) ;  next end
#				Dir.foreach(File.join(dir, subdir)) do |file|
#					if file == @disc.freedbString[0,8]
#						puts "Local file found #{File.join(dir, subdir, file)}"
#						# convert the string to an array, since ruby-1.9 handles these differently
#						@rawResponse = File.read(File.join(dir, subdir, file)).split("\n")
#						return true
#					end
#				end
#			end
#		end
#		return false
#	end
#
end
