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

require 'rubyripper/system/fileAndDir'

# A class that tries to locally find an entry in $HOME/.cddb
class LoadFreedbRecord

  def initialize(fileAndDir=nil)
    @file = fileAndDir ? fileAndDir : FileAndDir.instance()
  end

  # look for local entries
  def scan(discid)
    @discid = discid
    scanLocal()
  end

  # directly read a given cddb file, usefull for testing
  def read(testdisc)
    @freedbRecord = getFile(File.join(testdisc, 'freedb'))
    @status = 'ok'
  end

  # return the encoding found, usefull for testing
  def encoding ; return @encoding end

  # return the record
  def freedbRecord ; return @freedbRecord ; end

  # return the status
  def status ; return @status ; end

private

  # Find all matches in the cddb directory
  def scanLocal
    dir = File.join(ENV['HOME'], '.cddb')
    matches = @file.glob("#{dir}/*/#{@discid}")

    if matches.size > 0
      @status = 'ok'
      @freedbRecord = getFile(matches[0])
    else
      @status = 'noRecords'
    end
  end

  # file helper because of different encoding madness, it should be UTF-8
  # The only plausible way to test this is reloading the file
  # String manipulation afterwards seems not possible
  # Ruby 1.8 does not have encoding support yet
  def getFile(path)
    freedb = String.new
    if freedb.respond_to?(:encoding)
      ['r:UTF-8', 'r:ISO-8859-1', 'r:GB18030'].each do |encoding|
        @encoding = encoding
        freedb = @file.read(path, encoding)
        break if freedb.valid_encoding? && freedb != nil
      end

      if freedb == nil || !freedb.valid_encoding?
        @status = 'invalidEncoding'
        return nil
      else
        return freedb.encode('UTF-8')
      end
    else
      freedb = @file.read(path)
      return freedb
    end
  end
end
