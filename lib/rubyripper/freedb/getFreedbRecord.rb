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

# helper class to handle the http traffic
require 'rubyripper/freedb/cgiHttpHandler.rb'

#for translating characters to HTTP codes, space = %20 for instance
require 'cgi'

# This class tries to implement the freedb HTTP protocol (read-only)
# See http://ftp.freedb.org/pub/freedb/latest/CDDBPROTO for specs

class GetFreedbRecord
  attr_reader :status, :freedbRecord, :choices, :category, :finalDiscId

  def initialize(preferences, server=nil)
    @prefs = preferences
    @server = server ? server : CgiHttpHandler.new(@prefs)
  end

  # handle the initial connection with the freedb server
  def handleConnection(freedbString)
    @freedbString = freedbString
    analyzeQueryResult(queryFreedbForMatches())
  end

  # choose number in the array [0-XX] which result you want to return
  def choose(number)
    if @choices.nil?
      @status = 'noChoices'
    elsif @choices[number].nil?
      @status = "choiceNotValid: #{number}"
    else
      # simulate having found a single record in a query
      reply = "200 #{@choices[number]}"
      oneRecordFound(reply)
    end
  end

private

  # Query the freedb database for available matches.
  # There can be none, one or multiple hits, depending on the return code
  def queryFreedbForMatches()
    query = @server.path + "?cmd=cddb+query+" + CGI.escape("#{@freedbString}") +
"&hello=" + CGI.escape("#{@prefs.get('username')} #{@prefs.get('hostname')} \
rubyripper #{$rr_version}") + "&proto=6"

    # http requests return all output at once, even if multiple lines
    return @server.get(query)
  end

  # analyze the reponse code and assign neccesary action
  def analyzeQueryResult(reply)
    code = reply[0..2].to_i

    case code
    when 200 ; oneRecordFound(reply)
    when 211 || 210 ; multipleRecordsFound(reply)
    when 202 ; noRecordsFound()
    when 403 ; databaseCorrupt()
    else ; unknownCode(code)
    end
  end

  # in case no records are found
  def noRecordsFound() ; @status = "noMatches" ; end

  # in case a single record is found
  def oneRecordFound(reply)
    code, category, discid = reply.split()
    getRecord(category, discid)
  end

  # in case multiple records are found, skip header
  def multipleRecordsFound(reply)
    @choices = Array.new
    reply.split("\n")[1..-1].each do |line|
      @choices << line
    end
    @choices.pop if @choices[-1] == '.'

    # simulate one record found if firstHit == true
    if @prefs.get('firstHit') == true
      reply = "200 #{@choices[0]}"
      oneRecordFound(reply)
    else
      @status = 'multipleRecords'
    end
  end

  # in case the database is corrupt
  def databaseCorrupt() ; @status = "databaseCorrupt" ; end

  # in case the return code is unknown
  def unknownCode(code) ; @status = "unknownReturnCode: #{code}" ; end

  # retrieve the record
  def getRecord(category, discid)
    query = "#{@server.path}?cmd=cddb+read+" + CGI.escape("#{category} #{discid}") +
"&hello=" + CGI.escape("#{@prefs.get('username')} #{@prefs.get('hostname')} \
rubyripper #{$rr_version}") + "&proto=6"

    reply = @server.get(query)

    if reply[0..2] == '210'
      code, @category, @finalDiscId = reply.split()
      cleanup(reply)
      @status = 'ok'
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

    case code
    when 401 ; @status = 'cddbEntryNotFound'
    when 402 ; @status = 'serverError'
    when 403 ; databaseCorrupt()
    else ; unknownCode(code)
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
