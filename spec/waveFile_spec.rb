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

require 'rubyripper/waveFile'
require 'tempfile'

describe WaveFile do
  
  context "with a valid wave file as input" do
    before(:each) do
      tmpFile1 = Tempfile.new('tempWaveFile1')
      tmpFile1.write("RIFF\xE4\x24\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x02\x00\x44\xAC\x00\x00\x10\xB1\x00\x00\x02\x00\x04\x00data\xC0\x24\x00\x00")
      # 4 sectors
      tmpFile1.write("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2))
      tmpFile1.write("\x03\x03\x03\x03\x04\x04\x04\x04" * (588 / 2))
      tmpFile1.write("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2))
      tmpFile1.write("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2))
      tmpFile1.close()

      tmpFile2 = Tempfile.new('tempWaveFile2')
      tmpFile2.write("RIFF\x54\x09\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x02\x00\x44\xAC\x00\x00\x10\xB1\x00\x00\x02\x00\x04\x00data\x30\x09\x00\x00")
      # 1 sector
      tmpFile2.write("\x10\x10\x10\x10\x20\x20\x20\x20" * (588 / 2))
      tmpFile2.close()

      @waveFile1 = WaveFile.new(tmpFile1.path)
      @waveFile2 = WaveFile.new(tmpFile2.path)
    end
    
    it "should read individual sectors correctly" do
      @waveFile1.read(0).should == "\x01\x01\x01\x01\x02\x02\x02\x02" * (588/2)
      @waveFile1.read(1).should == "\x03\x03\x03\x03\x04\x04\x04\x04" * (588/2)
      @waveFile1.read(2).should == "\x05\x05\x05\x05\x06\x06\x06\x06" * (588/2)
      @waveFile1.read(3).should == "\x07\x07\x07\x07\x08\x08\x08\x08" * (588/2)
    end
    
    it "should return all of its data with audioData" do
      @waveFile1.audioData.should ==
        (("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2)) +
         ("\x03\x03\x03\x03\x04\x04\x04\x04" * (588 / 2)) +
         ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2)) +
         ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2)))
    end
    
    it "should know how many sectors it has" do
      @waveFile1.numSectors.should == 4
    end
    
    context "with a positive offset" do
      before(:each) do
        @waveFile1.offset = 3
      end

      it "should trim samples from the start and pad the end" do
        @waveFile1.audioData.should ==
          ("\x02\x02\x02\x02" +
           ("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2 - 2)) +
           ("\x03\x03\x03\x03\x04\x04\x04\x04" * (588 / 2)) +
           ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2)) +
           ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2)) +
           ("\x00\x00\x00\x00" * 3))
      end
      
      it "should correct the wave file sizes on save! when padMissingSamples false" do
        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector, plus 36 for header, minus 12 trimmed
        writtenData[4..7].unpack('V')[0].should == (2352 * 4 + 36 - 12)
        # 2352 bytes/sector, minus 12 trimmed
        writtenData[40..43].unpack('V')[0].should == (2352 * 4 - 12)
        # No padding.
        writtenData.length.should == (2352 * 4 + 44 - 12)
        writtenData[-4..-1].should == "\x08\x08\x08\x08"
      end

      it "should not correct wave file sizes on save! when padMissingSamples true" do
        @waveFile1.padMissingSamples = true
        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector, plus 36 for header
        writtenData[4..7].unpack('V')[0].should == (2352 * 4 + 36)
        # 2352 bytes/sector
        writtenData[40..43].unpack('V')[0].should == (2352 * 4)
        # Padding
        writtenData.length.should == (2352 * 4 + 44)
        writtenData[-4..-1].should == "\x00\x00\x00\x00"
      end
    end
    
    context "with a negative offset" do
      before(:each) do
        @waveFile1.offset = -3
      end

      it "should trim samples from the end and pad the start" do
        @waveFile1.audioData.should ==
          (("\x00\x00\x00\x00" * 3) +
           ("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2)) +
           ("\x03\x03\x03\x03\x04\x04\x04\x04" * (588 / 2)) +
           ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2)) +
           ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2 - 2) +
            "\x07\x07\x07\x07"))
      end
      
      it "should correct the wave file sizes on save! when padMissingSamples false" do
        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector, plus 36 for header, minus 12 trimmed
        writtenData[4..7].unpack('V')[0].should == (2352 * 4 + 36 - 12)
        # 2352 bytes/sector, minus 12 trimmed
        writtenData[40..43].unpack('V')[0].should == (2352 * 4 - 12)
        # No padding.
        writtenData.length.should == (2352 * 4 + 44 - 12)
        writtenData[44..47].should == "\x01\x01\x01\x01"
      end

      it "should not correct wave file sizes on save! when padMissingSamples true" do
        @waveFile1.padMissingSamples = true
        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector, plus 36 for header
        writtenData[4..7].unpack('V')[0].should == (2352 * 4 + 36)
        # 2352 bytes/sector
        writtenData[40..43].unpack('V')[0].should == (2352 * 4)
        # Padding
        writtenData.length.should == (2352 * 4 + 44)
        writtenData[44..47].should == "\x00\x00\x00\x00"
      end
    end

    context "when splicing" do
      it "should replace with the data of another WaveFile object" do
        @waveFile1.splice(1, @waveFile2.read(0))
        @waveFile1.audioData.should ==
          (("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2)) +
           ("\x10\x10\x10\x10\x20\x20\x20\x20" * (588 / 2)) +
           ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2)) +
           ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2)))

        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector, plus 36 for header
        writtenData[4..7].unpack('V')[0].should == (2352 * 4 + 36)
        # 2352 bytes/sector
        writtenData[40..43].unpack('V')[0].should == (2352 * 4)
        writtenData[(44 + 2352)..(44 + 2352 + 3)].should == "\x10\x10\x10\x10"
      end

      it "should replace the offset sector with the data" do
        @waveFile1.offset = 3
        @waveFile1.splice(1, @waveFile2.read(0))
        @waveFile1.audioData.should ==
          ("\x02\x02\x02\x02" +
           ("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2 - 2)) +
           ("\x03\x03\x03\x03\x04\x04\x04\x04\x03\x03\x03\x03") +
           ("\x10\x10\x10\x10\x20\x20\x20\x20" * (588 / 2)) +
           "\x06\x06\x06\x06" +
           ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2 - 2)) +
           ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2)) +
           ("\x00\x00\x00\x00" * 3))

        @waveFile1.padMissingSamples = true
        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector, plus 36 for header
        writtenData[4..7].unpack('V')[0].should == (2352 * 4 + 36)
        # 2352 bytes/sector
        writtenData[40..43].unpack('V')[0].should == (2352 * 4)
        writtenData[(44 + 2352 - 4)..(44 + 2352 + 3)].should == "\x03\x03\x03\x03\x10\x10\x10\x10"
      end
    end
  end
end
