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
require 'rubyripper/system/network'
require 'rubyripper/preferences/main'

# This class tries to implement the freedb HTTP protocol (read-only)
# See http://ftp.freedb.org/pub/freedb/latest/CDDBPROTO for specs

class GetFreedbRecord
  attr_reader :status, :freedbRecord, :choices, :category, :finalDiscId

  def initialize(network=nil, prefs=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @network = network ? network : Network.new()
  end

  # handle the initial connection with the freedb server
  def queryDisc(freedbString)
    @freedbString = freedbString
    @network.setupConnection('cgi')
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
    query = @network.path + "?cmd=cddb+query+" + @network.encode("#{@freedbString}") +
"&hello=" + @network.encode("#{@prefs.username} #{@prefs.hostname} \
rubyripper #{$rr_version}") + "&proto=6"

    # http requests return all output at once, even if multiple lines
    return @network.get(query)
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
    if @prefs.firstHit == true
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
    query = "#{@network.path}?cmd=cddb+read+" + @network.encode("#{category} #{discid}") +
"&hello=" + CGI.escape("#{@prefs.username} #{@prefs.hostname} \
rubyripper #{$rr_version}") + "&proto=6"

    reply = @network.get(query)

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
