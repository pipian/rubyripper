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

# A class that interprets the toc with the info of cd-info
# Quite reliable for detecting data tracks and generating freedb strings
# Notice that cdparanoia and cd-info might have conflicting results for
# discs with data tracks. For freedb calculation cd-info is correct, for
# detecting the audio part, cdparanoia is correct.
class ScanDiscCdinfo

	# * cdrom = a string with the location of the drive
	# * testRead = a string with output of cd-info for unit testing purposes
	def initialize(cdrom = '/dev/cdrom', testRead = false)		
		@cdrom = cdrom
		
		checkArguments()
		@settings = Hash.new
		@settings['startSector'] = Hash.new
		@settings['dataTracks'] = Array.new
		
		@status = _('ok')
		query = testRead || `cd-info -C #{@cdrom}`
		
		if isValidQuery(query)
			parseQuery(query)
			addExtraInfo()
		end
	end

	# return the status, _('ok') is good
	def status ; return @status ; end

	# return the settings variable
	def getInfo(key=false)
		if key == false
			return @settings
		else
			if @settings.key?(key)
				return @settings[key]
			else
				return false
			end
		end
	end

private

	# check the parameters
	def checkArguments
		unless @cdrom.class == String
			raise ArgumentError, "cdrom parameter must be a string"
		end
	end

	# check the query result for errors
	def isValidQuery(query)
		if query.include?('WARN: Can\'t get file status')
			@status = _('ERROR: Not a valid cdrom drive')
		elsif query.include?('Usage:')
			@status = _('ERROR: invalid parameters for cd-info')
		elsif query.include?('WARN: error in ioctl')
			@status = _('ERROR: No disc found')
		end
		
		return @status == _('ok')
	end

	# minutes:seconds:sectors to sectors
	# correct for offset of 150 to match cdparanoia
	def toSectors(time)
		count = -150
		minutes, seconds, sectors = time.split(':')
		count += sectors.to_i
		count += (seconds.to_i * 75)
		count += (minutes.to_i * 60 * 75)
		return count
	end

	# now back to time
	def toTime(sectors)
		minutes = sectors / (60*75)
		seconds = ((sectors % (60*75)) / 75)
		frames = sectors - minutes*60*75 - seconds*75
		return "%02d:%02d.%02d" % [minutes, seconds, frames]
	end

	# store the info of the query in variables
	def parseQuery(query)
		currentTrack = 0
		query.each_line do |line|
			@settings['version'] = line if line =~ /cd-info version/			
			@settings['vendor'] = $'.strip if line =~ /Vendor\s+:\s/
			@settings['model'] = $'.strip if line =~ /Model\s+:\s/
			@settings['revision'] = $'.strip if line =~ /Revision\s+:\s/
			@settings['discMode'] = $'.strip if line =~ /Disc mode is listed as:\s/
			
			# discover a track			
			if line =~ /\s+\d+:\s/
				currentTrack += 1
				trackinfo = $'.split(/\s+/)
				@settings['startSector'][currentTrack] = toSectors(trackinfo[0])
				@settings['dataTracks'] << currentTrack if trackinfo[2] == "data"
			end

			if line =~ /leadout/
				line =~ /\d\d:\d\d:\d\d/
				@settings['totalSectors'] = toSectors($&)
				break
			end
		end
		@settings['tracks'] = currentTrack
	end

	# Add some extra info that is calculated
	def addExtraInfo
		@settings['devicename'] = "#{@settings['vendor']} "
		@settings['devicename'] += "#{@settings['model']} "
		@settings['devicename'] += "#{@settings['revision']}"
		@settings['playtime'] = toTime(@settings['totalSectors'])[0,5]
		@settings['audiotracks'] = @settings['tracks'] - @settings['dataTracks'].length
		(1..@settings['tracks']).each do |track|
			if not @settings['dataTracks'].include?(track)
				@settings['firstAudioTrack'] = track
				break
			end 
		end		

		# add some track info
		@settings['lengthSector'] = Hash.new
		@settings['lengthText'] = Hash.new
		@settings['startSector'].each do |key, value|
			if key == @settings['tracks']
				@settings['lengthSector'][key] = @settings['totalSectors'] - @settings['startSector'][key]
			else
				@settings['lengthSector'][key] = @settings['startSector'][key + 1] - value
			end
			@settings['lengthText'][key] = toTime(@settings['lengthSector'][key])
		end
	end
end
