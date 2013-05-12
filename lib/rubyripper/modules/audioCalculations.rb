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

# A shared module for all kinds of audio calculations and standard values
module AudioCalculations
  # Wave files have 75 audio frames / sectors for each second
  FRAMES_A_SECOND = 75
  
  # That makes up 60x75 frames for each minute
  FRAMES_A_MINUTE = 60 * FRAMES_A_SECOND
  
  # The maximum decibel level that 16-bits audio can contain
  MAX_DECIBEL_LEVEL_16_BIT = 96.0

  # The overhead of the .wav container (info about stereo vs mono, khz, etcetera)
  BYTES_WAV_CONTAINER = 44

  # Amount of bits a second for audio disc is 44100 (herz) * 16 (bits) * 2 (stereo) = 1411200
  # Amount of bytes a second is 1411200 / 8 = 176400
  # Amount of bytes a frame is 176400 / 75 = 2352
  BYTES_AUDIO_FRAME = 2352
  BYTES_AUDIO_SECOND = 2352 * FRAMES_A_SECOND

  # Each frame exists of 588 audio samples of 4 bytes
  # Samples are used to correct the drive reading offset
  # Note that offsets in cdparanoia can't be as big as a frame
  # The following commands return the same output, no matter the device
  # cdparanoia [.1000]-[.1000] -O 0 001.wav
  # cdparanoia [.1000]-[.1000] -O 588 002.wav
  # cdparanoia [.1000]-[.1000] -O -588 003.wav
  SAMPLES_A_FRAME = 588
  BYTES_AUDIO_SAMPLE = 4
  
  # minutes:seconds:sectors to sectors
  def toSectors(time)
    minutes, seconds, sectors = time.split(':')
    count = sectors.to_i
    count += (seconds.to_i * FRAMES_A_SECOND)
    count += (minutes.to_i * FRAMES_A_MINUTE)
    return count
  end

  # sectors to mm:ss:ff
  def toTime(sectors)
    return '' if sectors == nil
    minutes = sectors / (FRAMES_A_MINUTE)
    seconds = ((sectors % (FRAMES_A_MINUTE)) / FRAMES_A_SECOND)
    frames = sectors - minutes * FRAMES_A_MINUTE - seconds * FRAMES_A_SECOND
    return "%02d:%02d:%02d" % [minutes, seconds, frames]
  end
end