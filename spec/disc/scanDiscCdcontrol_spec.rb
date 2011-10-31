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

require 'rubyripper/disc/scanDiscCdcontrol'

describe ScanDiscCdcontrol do

  let(:prefs) {double('Preferences').as_null_object}
  let(:exec) {double('Execute').as_null_object}
  let(:scan) {ScanDiscCdcontrol.new(exec, prefs)}

  before(:each) do
    prefs.should_receive(:cdrom).at_least(:once).and_return('/dev/cdrom')
  end

  def setQueryReply(answer)
    exec.should_receive(:launch).with('cdcontrol -f /dev/cdrom info').and_return(answer)
  end

  def setStandardQueryReply
    setQueryReply(["   15  36:34.45   3:21.15  164445   15090  audio",
                   "   16  39:55.60   3:37.45  179535   16320  audio",
                   "  170  43:33.30         -  195855       -      -"])
  end
  
  context "When a queryresult is not a valid response" do
    it "should detect if cdcontrol is not installed" do
      setQueryReply(nil)
      scan.scan()
      scan.status.should == 'notInstalled'
    end

    it "should detect if the drive is not valid" do
      setQueryReply(['cdcontrol: /dev/cd0: No such file or directory'])
      scan.scan()
      scan.status.should == 'unknownDrive'
    end

    it "should detect a problem with parameters" do
      setQueryReply(['cdcontrol: invalid command, enter ``help'' for commands'])
      scan.scan()
      scan.status.should == 'wrongParameters'
    end

    it "should detect if there is no disc inserted" do
      setQueryReply(['cdcontrol: getting toc header: Device not configured'])
      scan.scan()
      scan.status.should == 'noDiscInDrive'
    end
  end

  context "When a query is a valid response" do
    it "should detect the startsector for each track" do
      setStandardQueryReply()
      scan.scan()
      scan.getStartSector(14).should == nil
      scan.getStartSector(15).should == 164445
      scan.getStartSector(16).should == 179535
      scan.getStartSector(17).should == nil
    end

    it "should detect the length in sectors for each track" do
      setStandardQueryReply()
      scan.scan()
      scan.getLengthSector(14).should == nil
      scan.getLengthSector(15).should == 15090
      scan.getLengthSector(16).should == 16320
      scan.getLengthSector(17).should == nil
    end

    it "should detect the length in mm:ss for each track" do
      setStandardQueryReply()
      scan.scan()
      scan.getLengthText(14).should == nil
      scan.getLengthText(15).should == '03:21.15'
      scan.getLengthText(16).should == '03:37.45'
      scan.getLengthText(17).should == nil
    end

    it "should detect the total amount of sectors for the disc" do
      setQueryReply(["  170  43:33.30         -  195855       -      -"])
      scan.scan()
      scan.totalSectors.should == 195855
    end

    it "should detect the playtime in mm:ss for the disc" do
      setQueryReply(["  170  43:33.30         -  195855       -      -"])
      scan.scan()
      scan.playtime.should == '43:31' #minus 2 seconds offset, without frames
    end

    it "should detect the amount of audiotracks" do
      setStandardQueryReply()
      scan.scan()
      scan.audiotracks.should == 2
    end

    it "should detect the first audio track" do
      setStandardQueryReply()
      scan.scan()
      scan.firstAudioTrack.should == 15
    end

    it "should detect if there are no data tracks on the disc" do
      setStandardQueryReply()
      scan.scan()
      scan.audiotracks.should == 2
      scan.dataTracks.should == []
      scan.tracks.should == 2
    end

    it "should detect the data tracks on the disc" do
      setQueryReply(["   13  61:11.22  12:36.09  275197   56709   data",
                     "  170  73:47.31         -  331906       -      -"])
      scan.scan()
      scan.audiotracks.should == 0
      scan.dataTracks.should == [13]
      scan.tracks.should == 1
    end
  end
end
