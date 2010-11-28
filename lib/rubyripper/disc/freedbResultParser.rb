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

# This class can read and interpret a freedb metadata message
class FreedbResultParser

	# setup actions to analyze the result
	# freedbResult = A string with the complete freedb metadata message
	def initialize(freedbResult)
		@freedbResult = freedbResult		
		@status = _('ok')
		@metadata = Hash.new
		@metadata['tracklist'] = Hash.new
		@metadata['varArtist'] = Hash.new
		checkArguments()
		if isValidQuery()
			analyzeResult()
			scanForVarious()
		end
	end

	# return the metadata, if unknown return false
	def getInfo(key)
		if @metadata.key?(key)
			return @metadata[key]
		else
			return false
		end
	end

	# If succesfull, status will be _('ok')
	def status ; return @status ; end

private
	# check the parameters
	def checkArguments()
		unless @freedbResult.class == String
			raise ArgumentError, "freedbResult must be a string!"
		end
	end

	# check if the format is recognized
	def isValidQuery
		if !@freedbResult.valid_encoding?
			@status = _('ERROR: The freedb string has no valid encoding')
		elsif @freedbResult.encoding.name != 'UTF-8'
			@status = _('ERROR: The freedb string is not UTF-8 encoded')
		end
		return @status == _('ok')
	end

	# analyze the output
	def analyzeResult
		discTitle = String.new
		@freedbResult.each_line do |line|
			if line[0] == '#'
				next
			elsif line =~ /DISCID=/
				@metadata['discid'] = $'.strip()
			# a disc title can span two lines			
			elsif line =~ /DTITLE=/
				discTitle += $'.strip()
			elsif line =~ /DYEAR=/
				@metadata['year'] = $'.rstrip() if $'.strip().length > 0
			elsif line =~ /DGENRE=/
				@metadata['genre'] = $'.strip() 
			# a track title can span two lines
			elsif line =~ /TTITLE\d+=/
				track = $&[6..-2].to_i + 1		
				trackname = $'.rstrip()
				if @metadata['tracklist'].key?(track)
					# the first line is rstripped, so give an extra space when
					# the next line starts with a capital
					trackname = ' ' + trackname if trackname[0] =~ /[A-Z]/
					@metadata['tracklist'][track] << trackname
				else
					@metadata['tracklist'][track] = trackname
				end
			elsif line =~ /EXTD=/
				@metadata['extraDiscInfo'] = $'.strip() if $'.strip().length > 0
			end
		end
		@metadata['artist'], @metadata['album'] = discTitle.split(/\s\/\s/)
	end

	# try to detect various artists, separator can be ' / ' || ' - ' || ': '
	def scanForVarious
		various = true
		@metadata['tracklist'].each do |key, value|
			if value =~ /\s\/\s/
			elsif value =~ /\s-\s/
			elsif value =~ /:\s/			
			else
				various = false
				break			
			end
		end
		
		if various == true
			# save the original so the user can later undo this logic
			@metadata['oldTracklist'] = @metadata['tracklist'].dup()
			@metadata['tracklist'].each do |key, value|		
				if value =~ /\s\/\s/
				elsif value =~ /\s-\s/
				elsif value =~ /:\s/			
				end
				# $` = part before the matching part, $' = part after the matching part
				@metadata['varArtist'][key], @metadata['tracklist'][key] = $`, $'
			end
		end
	end
end
