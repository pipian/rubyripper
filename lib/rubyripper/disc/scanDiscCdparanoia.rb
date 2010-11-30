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

require 'rubyripper/permissionDrive.rb'

# A class that interprets the toc with the info of cdparanoia
# It's purpose is pure for ripping the correct audio, not for
# creating the freedb string. Cd-info is better for that.
# Before ripping, the function checkOffsetFirstTrack should be called.
class ScanDiscCdparanoia

	# * deps = instance of Dependency class
	# * settings = hash with all settings
	# * testRead = a string with all cdparanoia output used for unit testing
	def initialize(deps, settings, testRead = false)
		@deps = deps
		@settings = settings
		checkArguments()		
		setDefaultVariables()
		
		@status = 'ok'
		query = testRead || `cdparanoia -d #{@cdrom} -vQ 2>&1`
		
		# some versions of cdparanoia don't support the cdrom parameter
		if query.include?('USAGE')
			query = testRead || `cdparanoia -vQ 2>&1`
			@disc['multipleDriveSupport'] = false
		end
		
		if isValidQuery(query)
			parseQuery(query)
			addExtraInfo()
			checkOffsetFirstTrack()
		end
		
		if @status == 'ok' && !testRead
			@status = PermissionDrive.new(@cdrom, query, @deps).status
		end
	end

	# return the settings variable
	def getInfo(key=false)
		if key == false
			return @disc
		else
			if @disc.key?(key)
				return @disc[key]
			else
				return false
			end
		end
	end

	# return the status, 'ok' is good
	def status ; return @status ; end

private

	# check the parameters
	def checkArguments
		unless @deps.class == Dependency
			raise ArgumentError, "deps parameter must be a Dependency class"
		end
		unless @settings.class == Hash
			raise ArgumentError, "prefs parameter must be a Hash"
		end
	end

	# setting some default variables
	def setDefaultVariables
		@cdrom = @settings['cdrom']
		@disc = Hash.new
		@disc['audiotracks'] = 0
		@disc['startSector'] = Hash.new
		@disc['lengthSector'] = Hash.new
		@disc['lengthText'] = Hash.new
		@disc['dataTracks'] = Array.new
		@disc['multipleDriveSupport'] = true
	end

	# check the query result for errors
	def isValidQuery(query)
		if query.include?('Unable to open disc')
			@status = _("No disc found in drive %s.\n\n\
Please put an audio disc in first...") %[@cdrom]
		elsif query.include?('USAGE')
			@status = _('ERROR: %s doesn\'t recognize the parameters.') %['Cdparanoia']
		elsif query.include?('No such file or directory')
			@status = _('ERROR: drive %s is not found') %[@cdrom]
		end
		
		return @status == 'ok'
	end

	# store the info of the query in variables
	def parseQuery(query)
		currentTrack = 0
		query.each_line do |line|
			if line[0,5] =~ /\s+\d+\./
				currentTrack += 1
				tracknumber, lengthSector, lengthText, startSector = line.split
				if currentTrack == 1
					@disc['firstAudioTrack'] = tracknumber[0..-2].to_i
				end
				@disc['lengthSector'][currentTrack] = lengthSector.to_i
				@disc['startSector'][currentTrack] = startSector.to_i
				@disc['lengthText'][currentTrack] = lengthText[1..-2]
			elsif line =~ /CDROM\D*:/
				@disc['devicename'] = $'.strip()
			elsif line[0,5] == "TOTAL"
				@disc['playtime'] = line.split()[2][1,5]
			end
		end
		@disc['audiotracks'] = currentTrack
	end

	# add some extra variables and add corrections
	def addExtraInfo
		if @disc['audioTracks'] == 0
			@status = _('ERROR: No audio tracks found!')
		end
		@disc['totalSectors'] = 0
		@disc['lengthSector'].each_value do |value|
			@disc['totalSectors'] += value		
		end
	end

	# When a data track is the first track on a disc, cdparanoia is acting
	# strange: In the query it is showing as a start for 1s track the offset of
	# the data track. When ripping this offset isn't used however !! To allow
	# a correct rip of this disc all startSectors have to be corrected. See 
	# also issue 196.
	
	# If there is no data track at the start, but we do have an offset this 
	# means some hidden audio part. This part is marked as track 0. You can
	# only assess this on a cd-player by rewinding from 1st track on.
	def checkOffsetFirstTrack()
		# correct the startSectors when a disc starts with data
		if @disc['firstAudioTrack'] != 1
			dataOffset = @disc['startSector'][1]
			@disc['startSector'].each_key do |key, value|
				@disc['startSector'][key] -= dataOffset
			end
		#do nothing extra when hidden audio shouldn't be ripped
		#in the cuesheet this part will be marked as a pregap (silence).
		elsif @settings['ripHiddenAudio'] == false
		# if size of hiddenAudio is bigger than minimum length, make track 0
		elsif (@disc['startSector'][1] != 0 && 
			@disc['startSector'][1] / 75.0 > @settings['minLengthHiddenTrack'])
			@disc['startSector'][0] = 0
			@disc['lengthSector'][0] = @disc['startSector'][1]
		# otherwise prepend it to the first track
		elsif @disc['startSector'][1] != 0
			@disc['lengthSector'][1] += @disc['startSector'][1]
			@disc['startSector'][1] = 0
		end
	end
end
