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

# class that gets the freedb string
# TODO pass the proper settings if a data track is found
# cdparanoia doesn't report this, but cd-info does
class FreedbString

	# * deps = instance of Dependency class
	# * cdrom = string with location of the cdrom drive
	# * disc = instance of scanDiscCdparanoia
	def initialize(dependency, preferences, scanDiscCdparanoia, fireCommand, scanDiscCdinfo)
		@deps = dependency
		@prefs = preferences
		@disc = scanDiscCdparanoia
		@fire = fireCommand
		@cdinfo = scanDiscCdinfo
		checkArguments()
		
		@cdrom = @prefs['cdrom']
		@startSector = @disc.get('startSector')
		@lengthSector = @disc.get('lengthSector')
		@audiotracks = @lengthSector.keys.length		
		@freedbString = ''

		if autoCalcFreedb() == false
			puts _("warning: discid or cd-discid isn't found on your system!)")
			puts _("Using fallback...")
			manualCalcFreedb()
		else
			@discid = @freedbString.split()[0]
		end
	end

	# return the freedb identification string
	def getFreedbString
		return @freedbString
	end

	# return the discid (part of the freedb identification string)
	def getDiscId
		return @discid
	end

private
	# check the arguments
	def checkArguments
		unless @deps.class == Dependency
			raise ArgumentError, "deps parameter must be a Dependency class"
		end
		unless @prefs.respond_to?(:get)
			raise ArgumentError, "prefs parameter must be a Preferences class"
		end
		unless @disc.respond_to?(:get)
			raise ArgumentError, "disc parameter must be a ScanDiscCdparanoia class"
		end
		unless @fire.respond_to?(:launch)
			raise ArgumentError, "fire parameter must be a FireCommand class"
		end
		unless @cdinfo.respond_to?(:get)
			raise ArgumentError, "cd-info parameter must be a ScanDiscCdinfo class"
		end
	end

	# try to fetch freedb string with help programs
	def autoCalcFreedb
		# mac OS needs to unmount the disc first
		if RUBY_PLATFORM.include?('darwin') && @deps.get('diskutil')
			@fire('diskutil', "diskutil unmount #{@cdrom}")			
		end
			
		if @deps.get('discid')
			@freedbString = @fire.launch('discid', "discid #{@cdrom}")
		elsif @deps.get('cd-discid')
			@freedbString = @fire.launch('cd-discid', "cd-discid #{@cdrom}")
		end
		
		# mac OS needs to mount the disc again
		if RUBY_PLATFORM.include?('darwin') && @deps.get('diskutil')
			@fire('diskutil', "diskutil mount #{@cdrom}")					
		end

		return !@freedbString.empty?
	end

	# try to calculate it ourselves
	def manualCalcFreedb
		tryCdinfo()
		setDiscId()
		buildFreedbString()
	end

	# try to use Cd-info to read the toc reliably
	def tryCdinfo
		if @deps.get('cd-info')
			@cdinfo.scan
			if @cdinfo.status == 'ok'
				@startSector = @cdinfo.getInfo('startSector')
				@lengthSector = @cdinfo.getInfo('lengthSector')
				@audiotracks = @cdinfo.getInfo('tracks')
			end
		end
	end

	# The freedb checksum is calculated as follows:
	# * for each track determine the amount of seconds it starts (offset=150)
	# * then count the individual numbers up to the total
	# * For example if seconds = 338 seconds, total is added with 3+3+8=14
	def setChecksum
		total = 0

		@startSector.keys.sort.each do |track|
			seconds = (@startSector[track] + 150) / 75
			seconds.to_s.split(/\s*/).each{|s| total += s.to_i} 
		end

		return total
	end

	# Calculate the discid using some magic which make my brain hurt itself
	def setDiscId
		@totalSectors = @startSector[@audiotracks] - @startSector[1]
		@totalSectors += @lengthSector[@audiotracks]

		@totalSeconds = @totalSectors / 75

		@discid =  ((setChecksum() % 0xff) << 24 | @totalSeconds << 8 | @audiotracks).to_s(16)
	end

	# now build the freedb string
	# this consists of:
	# * discid
	# * amount of tracks
	# * each starting sector, corrected with 150 offset
	# * total seconds of playtime
	def buildFreedbString
		@freedbString << "#{@discid} "
		@freedbString << "#{@audiotracks} "
		
		@startSector.keys.sort.each do |key|
			@freedbString << "#{@startSector[key] + 150} "
		end
		
		@freedbString << "#{(@totalSectors + 150) / 75}"
	end
end
