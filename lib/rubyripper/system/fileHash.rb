#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012  Bouke Woudstra (boukewoudstra@gmail.com)
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

# for md5 calculation
require 'digest/md5'
# for CRC32 calculation
require 'zlib'
require 'rubyripper/modules/audioCalculations'

class FileHash
  include AudioCalculations
  
  def initialize(filename, prefs=nil)
    @filename = filename
    @prefs = prefs ? prefs : Preferences::Main.instance
    @digest_md5 = Digest::MD5.new()
    @digest_crc32 = Zlib.crc32()
  end
  
  def calculate
    puts "DEBUG: Start of hashes algorithm #{Time.now}." if @prefs.debug
    calculateHashes()
    puts "DEBUG: End of hashes algorithm #{Time.now}." if @prefs.debug
  end
  
  def md5
    return @digest_md5.hexdigest
  end
  
  def crc32
    return "%08X" % [@digest_crc32]
  end
  
private

  # calculate the MD5 hash of the whole file
  # calculate the CRC hash of the music part
  def calculateHashes    
    File.open(@filename, 'r') do |inputfile|
      @digest_md5 << inputfile.read(BYTES_WAV_CONTAINER)
      
      while (line = inputfile.gets)
        @digest_md5 << line
        @digest_crc32 = Zlib.crc32(line, @digest_crc32)
      end
    end
  end
end