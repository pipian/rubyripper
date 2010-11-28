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
require 'rubyripper/disc/metadata.rb'

# The DiscHelper class manages the different scans of the disc
# This is mainly done with the help of cdparanoia
# The scan should typically take about 2 seconds

class DiscHelper
attr_reader :getMetadata, :getDisc,
:settings, :gui, :deps, :oldFreedbString, :testQuery

#:cdrom, :multipleDriveSupport, :audiotracks, :devicename,
#:playtime, :freedbString, :totalSectors, :freedb, :error,
#:discId, :toc, :tocStarted, :tocFinished, :getFreedbInfo,
#:getStartSector, :getLengthSector, :getLengthText, :getFileSize,
#:settings, :gui, :deps, :oldFreedbString, :testQuery, :testCdInfo

	def initialize(settings, gui, deps, oldFreedbString = '', testQuery = false)
		@settings = settings
		@gui = gui
		@deps = deps
		# string of previous scan
		@oldFreedbString = oldFreedbString
		# for testing purposes the disc query can be provided	
		@testQuery = testQuery

		# status for the class
		@status = _('ok')

		checkArguments()
		if isAudioDisc()
			startFreedb()
			prepareToc() # use help of cdrdao to get info about pregaps etcetera
		end
	end
	
	# check for valid arguments
	def checkArguments()
		unless @settings.class == Hash
			raise ArgumentError, "settings parameter must be a hash"
		end
		unless @gui.respond_to?(:update)
			raise ArgumentError, "The gui parameter is a class which " +
			"needs at least needs the \"update\" function"
		end
		unless @deps.class == Dependency
			raise ArgumentError, "deps parameter must be an instance of Dependency"
		end
		unless @oldFreedbString.class == String
			raise ArgumentError, "oldFreedbString parameter must be a string"
		end
		unless @testQuery == false || @testQuery.class == String
			raise ArgumentError, "query parameter must be false or a string"
		end
	end

	# initiate the scanning of cdparanoia output and return it a disc is found
	def isAudioDisc
		if @deps.getForcedDeps('Cdparanoia')
			@disc = ScanDiscCdparanoia.new(@deps, @settings)
			@status = @disc.status
			return @status == _('ok')
		else
			@status = _('Cdparanoia not found, can\'t scan disc!')
			return false
		end
	end

	# retrieve information of the disc retrieved by cdparanoia
	def getDisc(key=false)
		if key == false
			return @disc.getInfo()
		else
			@disc.getInfo(key)
		end
	end

	# get the freedb string and launch the freedb class
	def startFreedb
		@metadata = Metadata.new(@deps, @settings, @disc)

	end

	# retrieve information of the disc retrieve via freedb
	def getMetadata(key=false)
		if key == false
			return @freedb.getInfo()
		else
			@freedb.getInfo(key)
		end
	end

	# use cdrdao to scan for exact pregaps, hidden tracks, pre_emphasis
	def prepareToc
		if @settings['create_cue'] && @deps.getOptionalDeps['Cdrdao']
			@cdrdaoThread = Thread.new{advancedToc()}
		elsif @settings['create_cue']
			puts "Cdrdao not found. Advanced TOC analysis / cuesheet is skipped."
			@settings['create_cue'] = false # for further assumptions later on
		end
	end

	# start the Advanced toc instance
	def advancedToc
		@tocStarted = true
		@toc = AdvancedToc.new(@settings)
	end

	# update the Disc class with actual settings and make a cuesheet
	def updateSettings(settings)
		@settings = settings
		
		# user may have enabled cuesheet after the disc was scanned
		# @toc is still nil because the class isn't finished yet
		prepareToc() if @tocStarted == false
		
		# if the scanning thread is still active, wait for it to finish
		@cdrdaoThread.join() if @cdrdaoThread != nil
		
		# update the length of the sectors + the start of the tracks if we're 
		# prepending the gaps
		# also for the image since this is more easy with the cuesheet handling
		if @settings['pregaps'] == "prepend" || @settings['image']
			prependGaps()
		end
		
		# only make a cuesheet when the toc class is there
		@cue = Cuesheet.new(@settings, @toc) if @toc != nil
	end

	# prepend the gaps, so rewrite the toc info
	# notice that cdparanoia appends by default
	def prependGaps
		(2..@audiotracks).each do |track|
			pregap = @toc.getPregap(track)
			@lengthSector[track - 1] -= pregap
			@startSector[track] -= pregap
			@lengthSector[track] += pregap
		end
			             
		if @settings['debug']
			puts "Debug info: gaps are now prepended"
			puts "Startsector\tLengthsector"
			(1..@audiotracks).each do |track|
				puts "#{@startSector[track]}\t#{@lengthSector[track]}"
			end
		end             
	end

	# return the startSector, example for track 1 getStartSector(1)
	def getStartSector(track)
		if track == "image"
			@startSector.key?(0) ? @startSector[0] : @startSector[1]
		else
			if @startSector.key?(track)
				return @startSector[track]
			else
				return false
			end
		end
	end

	# return the sectors of the track, example for track 1 getLengthSector(1)
	def getLengthSector(track)
		if track == "image"
			return @totalSectors
		else
			return @lengthSector[track]
		end
	end

	# return the length of the track in text, 
	# example for track 1 getLengthSector(1)
	def getLengthText(track)
		if track == "image"
			return @playtime
		else
			return @lengthText[track]
		end
	end

	# return the length in bytes of the track, 
	# example for track 1 getFileSize(1)
	def getFileSize(track)
		if track == "image"
			return 44 + @totalSectors * 2352
		else
			return 44 + @lengthSector[track] * 2352
		end
	end

	# help function for passing to Freedb class
	def getFreedbInfo(choice=false)
		if choice == false # first time
			@freedb.freedb(@settings, @settings['first_hit'])
		else # specific disc is chosen (after multiple discs reported)
			@freedb.freedbChoice(choice)
		end
		return @freedb.status
	end
end

