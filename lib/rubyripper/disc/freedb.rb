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

require 'net/http' #automatically loads the 'uri' library
require 'cgi' #for translating characters to HTTP codes, space = %20 for instance

# The Freedb class tries to fetch the metadata from the freedb server
# See http://ftp.freedb.org/pub/freedb/latest/CDDBPROTO for protocol

class Freedb

	# freedbString = the identifying message for the disc in the freedb database
	# settings = hash with all settings
	# server = instance of the CgiHttpHandler class
	def initialize(freedbString, settings, server)
		@freedbString = freedbString
		@settings = settings
		@server = server
		checkArguments()		

		@status = _('ok')
		@freedbResult = String.new
		handleConnection()
	end

	# if succesfull, return _('ok')
	def status ; return @status ; end

	# return the freedb metadata string
	def freedbResult ; return @freedbResult end

	# from the different choises, choose one
	def makeChoice(choice=false)
		if choice != false
			if choice == @choices.size - 1 # keep defaults?
				@status = true
				return true
			end
			@category, @discid = @choices[choice].split
		end
		rawResponse()
		@tracklist.clear() #Now fill it with the real tracknames
		handleResponse()
		@status = true
	end

private
	# verify if correct parameters are passed
	def checkArguments
		unless @freedbString.class == String
			raise ArgumentError, "freedbString must be a string"		
		end

		unless @settings.class == Hash
			raise ArgumentError, "settings must be a hash".
		end

		unless @server.respond_to?(:configConnection)
			raiser ArgumentError, "server must be an instance of CgiHttpHandler"
		end
	end

	# handle the initial connection with the freedb server
	def handleConnection
		@url = URI.parse(@settings['site'])
		@server.configConnection(@url)
		
		response = queryFreedbForMatches()
		puts response if @verbose

		analyzeQueryResult(response)
		if @status == _('ok')
			
		end
	end

	# Query the freedb database for available matches.
	# There can be none, one or multiple hits, depending on the return code
	def queryFreedbForMatches()
		query = CGI.espace("#{@url.path}?cmd=cddb+query+#{@freedbString}\
&hello=#{@username} #{@hostname} rubyripper #{$rr_version}&proto=6")
		puts query if @verbose
		
		# http requests return all output at once, even if multiple lines		
		answer = @server.get(query)
	end

	# analyze the reponse message for the query
	def analyzeQueryResult(response)
		@choices = Array.new

		if response[0..2] == '200' #single hit
			@choices << response[4..-1]
		elsif response[0..2] == '211' #multiple hits
			response.each_line do |line|
				if line[0..2] != '211' && line != '.'
					@choices << line
				end
			end
			@choices << _("Keep defaults / don't use freedb")
		elsif response[0..2] == '202'
			@status = ["noMatches", _("No match in Freedb database. Default values are used.")]
		elsif response[0..2] == '403'
			@status = ["databaseCorrupt", _("The database is corrupt and cannot return values")]
		else
			@status = ["unknownReturnCode", _("cddb_query return code = %s. Return code not supported.") % [@answer[0..2]]]		
		end
	end

	# fetches the actual metadata
	def rawResponse #Retrieve all usefull metadata into @rawResponse
		@query = @url.path + "?cmd=cddb+read+" + CGI.escape("#{@category} #{@discid}") + "&hello=" + 
			CGI.escape("#{@freedbSettings['username']} #{@freedbSettings['hostname']} rubyripper #{$rr_version}") + "&proto=6"
		if @verbose ; puts "Created fetch string: #{@query}" end
		
		response, answer = @server.get(@query)
		answers = answer.split("\n")
		answers.each do |line|
			line.chomp!
			@rawResponse << line unless (line == nil || line[-1,1] == '=' ||line[0,1] == '#' || line[0,1] == '.' )
		end
		saveResponse()
	end
end

#	# save it locally for later use TODO
#	def saveResponse
#		if File.exist?(@settings['freedbCache'])
#			@metadataFile = YAML.load(File.open(@settings['freedbCache']))
#		else
#			@metadataFile = Hash.new
#		end
#
#		@metadataFile[@disc.freedbString] = @rawResponse
#		
#		file = File.new(@settings['freedbCache'], 'w')
#		file.write(@metadataFile.to_yaml)
#		file.close()
#	end
#end
	
# save any changes made by the user TODO
#	def saveChanges
#		@rawResponse = Array.new
#		@rawResponse << "DTITLE=#{@artist} \/ #{@album}"
#		@rawResponse << "DYEAR=#{@year}"
#		@rawResponse << "DGENRE=#{@genre}"
#		
#		@disc.audiotracks.times do |index|
#			if @varArtists.empty?
#				@rawResponse << "TTITLE#{index}=#{@tracklist[index]}"
#			else
#				@rawResponse << "TTITLE#{index}=#{@varArtists[index]} / #{@tracklist[index]}"
#			end
#		end
#		saveResponse()
#		return true
#	end
#	def undoVarArtist TODO
#		# first backup in case we want to revert back
#		@varArtistsBackup = @varArtists.dup()
#		@varTracklistBackup = @tracklist.dup()
#
#		# reset original values
#		@varArtists = Array.new
#
#		# restore the tracklist
#		@tracklist = @backupTracklist.dup
#	end

#reset to various artists when originally detected as such and made undone
#	def redoVarArtist TODO
#		if !@backupTracklist.empty? && !@varArtistsBackup.empty?
#			@tracklist = @varTracklistBackup
#			@varArtists = @varArtistsBackup
#		end
#	end
#end
#	def setVariables
#		@artist = _('Unknown')
#		@album = _('Unknown')
#		@genre = _('Unknown')
#		@year = '0'
#		@discNumber = false
#		@tracklist = Array.new
#		@disc.audiotracks.times{|number| @tracklist << _("Track %s") % [number + 1]}
#		@rawResponse = Array.new
#		@choices = Array.new
#		@varArtists = Array.new
#		@varArtistsBackup = Array.new
#		@backupTracklist = Array.new
#		@status = false
#	end

#	def freedb(freedbSettings, alwaysFirstChoice=true)
#		@freedbSettings = freedbSettings
#		@alwaysFirstChoice = alwaysFirstChoice
#
#		if not @disc.freedbString.empty? #no disc found
#			searchMetadata()
#		else
#			@status = ["noAudioDisc", _("No audio disc found in %s") % [@cdrom]]
#		end
#	end
