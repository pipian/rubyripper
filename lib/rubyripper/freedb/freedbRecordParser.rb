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
class FreedbRecordParser
attr_reader :metadata, :status

  # setup actions to analyze the result
  # freedbRecord = A string with the complete freedb metadata message
  def parse(freedbRecord)
    @freedbRecord = freedbRecord

    if recordIsValid?()
      @metadata = {'tracklist'=> Hash.new, 'varArtist' => Hash.new}
      analyzeResult()
      scanForVarious()
      @status = 'ok'
    end
  end

  # revert the auto splitting feature
  def undoVarArtist
    @metadata['tracklist'] = @metadata['oldTracklist']
    @metadata.delete('oldTracklist')
  end

  # and split yet again unless it is already splitted
  def redoVarArtist
    scanForVarious() unless @metadata.key?('oldTracklist')
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
        @metadata['discid'] = $'.strip()
      elsif line =~ /DTITLE=/
        discTitle = addValue(discTitle, $'.strip())
      elsif line =~ /DYEAR=/
        @metadata['year'] = $'.rstrip() if $'.strip().length > 0
      elsif line =~ /DGENRE=/
        @metadata['genre'] = $'.strip()
      elsif line =~ /TTITLE\d+=/
        track = $&[6..-2].to_i + 1
        @metadata['tracklist'][track] = addValue(@metadata['tracklist'][track], $'.rstrip())
      elsif line =~ /EXTD=/
        @metadata['extraDiscInfo'] = $'.strip() if $'.strip().length > 0
      end
    end
    @metadata['artist'], @metadata['album'] = discTitle.split(/\s\/\s/)
  end

   # if multiple rows can occur add a space again before the 2nd line
  def addValue(var, value)
    if var == nil || var.empty?
      var = value
    else
      var = "#{var} #{value}"
    end
  end

  # try to detect various artists, separator can be ' / ' || ' - ' || ': '
  def scanForVarious
    various = true
    @metadata['tracklist'].each do |key, value|
      if value =~ /\s\/\s/
      elsif value =~ /\s-\s/
      elsif value =~ /\s*:\s/
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
        elsif value =~ /\s*:\s/
        end
        # $` = part before the matching part, $' = part after the matching part
        @metadata['varArtist'][key], @metadata['tracklist'][key] = $`, $'
      end
    end
  end
end
