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

# This class tries to fetch the metadata from the freedb server
# See http://ftp.freedb.org/pub/freedb/latest/CDDBPROTO for protocol

class GetFreedbRecord

	# freedbString = the identifying message for the disc in the freedb database
	# settings = hash with all settings
	# server = instance of the CgiHttpHandler class
	def initialize(freedbString, settings, server)
		@freedbString = freedbString
		@settings = settings
		@server = server
		checkArguments()	

		@status = ['ok', _('ok')]
		@freedbRecord = String.new
		@choices = Array.new
		handleConnection()
	end

	# if succesfull, return _('ok')
	def status ; return @status ; end

	# return the freedb metadata string
	def freedbRecord ; return @freedbRecord ; end

	# return the different choices
	def getChoices ; return @choices ; end

	# choose number in the array [0-XX] which result you want to return
	def choose(number)
		if @choices.empty?
			raise ArgumentError, "ERROR, There are no choices!"
		elsif @choices[number] == nil
			raise ArgumentError, "ERROR, There is no option #{number}"
		end
		
		# fake single record found now		
		reply = "200 #{@choices[number]}"
		oneRecordFound(reply)		
	end

private
	# verify if correct parameters are passed
	def checkArguments
		unless @freedbString.class == String
			raise ArgumentError, "freedbString must be a string"		
		end

		unless @settings.class == Hash
			raise ArgumentError, "settings must be a hash"
		end

		unless @server.respond_to?(:configConnection)
			raise ArgumentError, "server must be an instance of CgiHttpHandler"
		end
	end

	# handle the initial connection with the freedb server
	def handleConnection
		@url = URI.parse(@settings['site'])
		@server.configConnection(@url)
		
		reply = queryFreedbForMatches()
		analyzeQueryResult(reply)
	end

	# Query the freedb database for available matches.
	# There can be none, one or multiple hits, depending on the return code
	def queryFreedbForMatches()
		query = @url.path + "?cmd=cddb+query+" + CGI.escape("#{@freedbString}") +
"&hello=" + CGI.escape("#{@settings['username']} #{@settings['hostname']} \
rubyripper #{$rr_version}") + "&proto=6"
		
		# http requests return all output at once, even if multiple lines		
		statusHttp, reply = @server.get(query)
		return reply
	end

	# analyze the reponse code and assign neccesary action
	def analyzeQueryResult(reply)
		code = reply[0..2].to_i

		if code == 200
			oneRecordFound(reply)
		elsif code == 211 || code == 210
			multipleRecordsFound(reply)
		elsif code == 202
			noRecordsFound()
		elsif code == 403
			databaseCorrupt()
		else
			unknownCode(reply)
		end
	end
	
	# in case no records are found
	def noRecordsFound()
		@status = ["noMatches", _("No match in Freedb database. Default \
values are used.")]
	end

	# in case a single record is found
	def oneRecordFound(reply)
		code, category, discid = reply.split()
		getRecord(category, discid)
	end

	# in case multiple records are found, skip header
	def multipleRecordsFound(reply)
		reply.split("\n")[1..-1].each do |line|
			@choices << line
		end
		@choices.pop if @choices[-1] == '.'
		
		# simulate one record found if firstHit == true
		if @settings['firstHit'] == true
			reply = "200 #{@choices[0]}"			
			oneRecordFound(reply)
		else
			@status = ['multipleRecords', _("Multiple records are found!")]
		end
	end

	# in case the database is corrupt
	def databaseCorrupt()
		@status = ["databaseCorrupt", _("The database is corrupt and cannot\
return values")]
	end

	# in case the return code is unknown
	def unknownCode(reply)
		@status = ["unknownReturnCode", _("cddb_query return code = %s.\n\
Return code is not supported.") % [reply[0..2]]]
	end

	# retrieve the record
	def getRecord(category, discid)
		query = "#{@url.path}?cmd=cddb+read+" + CGI.escape("#{category} #{discid}") + 
"&hello=" + CGI.escape("#{@settings['username']} #{@settings['hostname']} \
rubyripper #{$rr_version}") + "&proto=6"

		statusHttp, reply = @server.get(query)
		
		if reply[0..2] == '210'
			cleanup(reply)
			@status = ['ok', _('ok')]
		else
			errorReading(reply)
		end
	end

	# remove the header and footer of the reply
	# first line is confirmation message, last line may be just a dot(.)
	def cleanup(reply)
		reply = reply.split("\n")[1..-1] # remove the header
		@freedbRecord = reply.join("\n")
		@freedbRecord = @freedbRecord[0..-3] if @freedbRecord[-2..-1] = "\n."
	end

	# error handling for read command
	def errorReading(reply)
		code = reply[0..2].to_i
		
		puts "code = #{code}"

		if code == 401
			@status = ['cddbEntryNotFound', _('The disc can\'t be found!')]
		elsif code == 402
			@status = ['serverError', _('The Freedb server reports unknown problem')]
		elsif code == 403
			databaseCorrupt()
		else
			unknownCode(reply)
		end
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
