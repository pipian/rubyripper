#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2011  Ian Jacobi (pipian@pipian.com)
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

# The WaveFile class encapsulates a wave file and enables access to it
# as if it were a CD (i.e. sector-level manipulation of samples)

# NOTE: We assume that the path given to the initializer is a path to
# a CD-format wave file (i.e. 44.1kHz, 16-bit, stereo).  If the file
# is not an integral number of CD-sectors long (i.e. the number of
# samples is not divisible by 588), then it will be treated as if the
# last sector is missing samples.

# The offset property may be used to set the READ offset of the
# WaveFile object.  That is, offset should be the number of samples to
# read ahead (or behind, if negative) for a given sector.  IF THE WAVE
# FILE WAS ALREADY RIPPED TO ACCOUNT FOR THE OFFSET THIS SHOULD REMAIN
# 0!  If set, any subsequent calls to save! will write out the file
# starting with sector 0 taking offset into account (i.e. a positive
# offset will cause samples to be trimmed from the start on save!)

# For the purposes of saving, padMissingSamples will pad the WaveFile
# to an integral number of sectors by adding 0's to the beginning (if
# offset is negative) or end (if offset is non-negative) of the file.

require 'tempfile'
require 'fileutils'

class WaveFile
  attr_reader :path, :offset, :padMissingSamples
  attr_writer :offset, :padMissingSamples

  BYTES_WAV_CONTAINER = 44 # size of the wave header from cdparanoia
  BYTES_AUDIO_SECTOR = 2352 # size of a sector in bytes

  def initialize(path, offset=0, padMissingSamples=false)
    @path = path
    @newSectors = {}
    @file = File.open(@path, 'rb')
    @offset = offset
    @padMissingSamples = padMissingSamples
  end

  # Read a CD-audio sector (padding with 0's, regardless of padMissingSamples)
  def read(sector)
    start = BYTES_WAV_CONTAINER + sector * BYTES_AUDIO_SECTOR + @offset * 4
    
    if @newSectors.has_key?(sector)
      @newSectors[sector]
    else
      data = ""
      
      if start < BYTES_WAV_CONTAINER and @offset < 0
        # Pad the start.
        data += "\x00" * [(BYTES_WAV_CONTAINER - start),
                          BYTES_AUDIO_SECTOR].min
        start = BYTES_WAV_CONTAINER
      end
      
      if data.length == BYTES_AUDIO_SECTOR
        # We're before the start of the file, and only have padding!
        data
      elsif data.length < BYTES_AUDIO_SECTOR
        @file.seek(start, IO::SEEK_SET)
        buffer = @file.read(BYTES_AUDIO_SECTOR - data.length)
        if !buffer.nil?
          data += buffer
        end
        
        if data.length < BYTES_AUDIO_SECTOR
          # Pad the end.
          data += "\x00" * (BYTES_AUDIO_SECTOR - data.length)
        end
        
        data
      end
    end
  end

  # Return all audio data (including padding, regardless of padMissingSamples)
  def audioData
    data = ""
    (1..numSectors).each do |sector|
      data += read(sector - 1)
    end
    data
  end

  def numSectors
    audioSize = @file.stat.size - BYTES_WAV_CONTAINER
    audioSize / BYTES_AUDIO_SECTOR + ((audioSize % BYTES_AUDIO_SECTOR > 0) ? 1 : 0)
  end

  # Set the contents of the sector to (the raw sample data in) other.
  #
  # this.splice!(sector, that.read(sector)) will replace the contents
  # of sector number [sector] in this with the contents of sector
  # number [sector] in (the WaveFile) that.
  def splice(sector, data)
    if sector >= 0 and sector < numSectors and data.length == BYTES_AUDIO_SECTOR
      @newSectors[sector] = data
    end
  end

  # NOTE: After saving, offset will be 0.
  def save!
    # Write out the changes to a tempfile.
    
    # Do we pad the missing samples?
    if @padMissingSamples
      audioSize = numSectors * BYTES_AUDIO_SECTOR
    else
      audioSize = @file.stat.size - BYTES_WAV_CONTAINER
      if @offset != 0
        audioSize -= @offset.abs * 4
      end
    end
    
    f = Tempfile.open(File.basename(@path), :encoding => 'ascii-8bit')
    # WAVE header
    f.write("RIFF")
    f.write([audioSize + 36].pack("V"))
    f.write("WAVE")
    f.write("fmt \x10\x00\x00\x00\x01\x00\x02\x00\x44\xAC\x00\x00\x10\xB1\x02\x00\x04\x00\x10\x00")
    f.write("data")
    f.write([audioSize].pack("V"))
    if @padMissingSamples
      (1..numSectors).each do |sector|
        f.write(read(sector - 1))
      end
    elsif @offset > 0
      # Padding is at the end.
      bytesWritten = 0
      (1..numSectors).each do |sector|
        if bytesWritten + BYTES_AUDIO_SECTOR < audioSize
          f.write(read(sector - 1))
          bytesWritten += BYTES_AUDIO_SECTOR
        elsif bytesWritten < audioSize
          f.write(read(sector - 1)[0..(audioSize - bytesWritten - 1)])
          bytesWritten = audioSize
        else
          break
        end
      end
    else
      # Padding is at the beginning.
      bytesWritten = @offset * 4
      (1..numSectors).each do |sector|
        if bytesWritten <= -BYTES_AUDIO_SECTOR
          # Don't bother writing out the sector at all
          bytesWritten += BYTES_AUDIO_SECTOR
        elsif bytesWritten < 0
          f.write(read(sector - 1)[(0 - bytesWritten)..(BYTES_AUDIO_SECTOR - 1)])
          bytesWritten += BYTES_AUDIO_SECTOR
        elsif bytesWritten + BYTES_AUDIO_SECTOR <= audioSize
          f.write(read(sector - 1))
          bytesWritten += BYTES_AUDIO_SECTOR
        else
          break
        end
      end
    end
    f.close()

    # Reset the state and reload the file with offset 0.
    @file.close()
    FileUtils.move(f.path, @path, :force => true)
    @file = File.open(@path, 'rb')
    @offset = 0
  end

end
