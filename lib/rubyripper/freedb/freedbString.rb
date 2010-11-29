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
	# * test = false, 'manual' for testing the auto generation or the complete
	# freedbstring, faking a helpprogram
	def initialize(deps, settings, disc, test=false)
		@deps = deps
		@cdrom = settings['cdrom']
		@startSector = disc.getInfo('startSector')
		@lengthSector = disc.getInfo('lengthSector')
		@test = test

		checkArguments()
		@audiotracks = @lengthSector.keys.length		
		@freedbString = ''

		if autoCalcFreedb() == false
			if test == false
				puts _("warning: discid or cd-discid isn't found on your system!)")
				puts _("Using fallback...")
			end
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
		unless @cdrom.class == String
			raise ArgumentError, "cdrom parameter must be a string"
		end
		unless @startSector.class == Hash
			raise ArgumentError, "startSector parameter must be a hash"
		end
		unless @lengthSector.class == Hash
			raise ArgumentError, "lengthSector parameter must be a hash"
		end
	end

	# try to fetch freedb string with help programs
	def autoCalcFreedb
		# mac OS needs to unmount the disc first
		if RUBY_PLATFORM.include?('darwin') && @deps.getOptionalDeps('diskutil')
			`diskutil unmount #{@cdrom}`			
		end
			
		if @test == 'manual'
			@freedbString = ''
		elsif @test != false
			@freedbString = @test
		elsif @deps.getOptionalDeps('discid')
			@freedbString = `discid #{@cdrom}`
		elsif @deps.getOptionalDeps('cd-discid')
			@freedbString = `cd-discid #{@cdrom}`
		end
		
		# mac OS needs to mount the disc again
		if RUBY_PLATFORM.include?('darwin') && @deps.getOptionalDeps('diskutil')
			`diskutil mount #{@cdrom}`					
		end

		return !@freedbString.empty?
	end

	# try to calculate it ourselves
	def manualCalcFreedb
		tryCdinfo() if not @test
		setDiscId()
		buildFreedbString()
	end

	# try to use Cd-info to read the toc reliably
	def tryCdinfo
		if @deps.getOptionalDeps('cd-info')
			require 'rubyripper/scanDiscCdinfo.rb'
			output = ScanDiscCdinfo.new()
			if output.status == _('ok')
				@startSector = output.getInfo('startSector')
				@lengthSector = output.getInfo('lengthSector')
				@audiotracks = output.getInfo('tracks')
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
