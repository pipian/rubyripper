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

require 'rubyripper/freedb/metadata'

# This class can read and interpret a freedb metadata message
class FreedbRecordParser
attr_reader :status, :md

  def initialize(md=nil)
    @md = md ? md : Metadata.new
  end

  # setup actions to analyze the result
  # freedbRecord = A string with the complete freedb metadata message
  def parse(freedbRecord)
    @freedbRecord = freedbRecord

    if recordIsValid?()
      analyzeResult()
      scanForVarious()
      @status = 'ok'
    end
  end

  # revert the situation before splitting
  def undoVarArtist
    @md.tracklist = @oldTracklist
    @md.varArtist = Hash.new
    @oldTracklist = Hash.new
  end

  # and split yet again unless it is already splitted
  def redoVarArtist
    scanForVarious() if @oldTracklist.empty?
  end

private

  # check if the string is ready for analyzing
  def recordIsValid?
    if !@freedbRecord.valid_encoding?
      @status = 'noValidEncoding'
    elsif @freedbRecord.encoding.name != 'UTF-8'
      @status = 'noUTF8Encoding'
    end
    return @status.nil?
  end

  # scan each line for usefull input
  def analyzeResult
    discTitle = String.new
    @freedbRecord.each_line do |line|
      if line[0] == '#'
        next
      elsif line =~ /DISCID=/
        @md.discid = $'.strip()
      elsif line =~ /DTITLE=/
        discTitle = addValue(discTitle, $'.strip())
      elsif line =~ /DYEAR=/
        @md.year = $'.rstrip() if $'.strip().length > 0
      elsif line =~ /DGENRE=/
        @md.genre = $'.strip()
      elsif line =~ /TTITLE\d+=/
        track = $&[6..-2].to_i + 1
        @md.tracklist[track] = addValue(@md.tracklist[track], $'.rstrip())
      elsif line =~ /EXTD=/
        @md.extraDiscInfo = $'.strip()
      end
    end
    @md.artist, @md.album = discTitle.split(/\s\/\s/)
  end

   # if multiple rows can occur add a space again before the 2nd line
  def addValue(var, value)
    if var == nil || var.empty?
      var = value
    else
      var = "#{var} #{value}"
    end
  end

  # if all tracks have a various pattern, split it
  def scanForVarious
    if findVariousPattern(split=false)
      @oldTracklist = @md.tracklist.dup()
      findVariousPattern(split=true)
    end
  end

  # detect the pattern, it can be ' / ' || ' - ' || ': '
  def findVariousPattern(split=false)
    @md.tracklist.each do |key, value|
      if value =~ /\s\/\s/
      elsif value =~ /\s-\s/
      elsif value =~ /\s*:\s/
      else break
      end

      @md.varArtist[key], @md.tracklist[key] = $`, $' if split
    end
  end
end
