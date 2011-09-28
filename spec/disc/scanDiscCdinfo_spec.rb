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

require 'spec_helper'

describe ScanDiscCdinfo do

  let(:prefs) {double('Preferences').as_null_object}
  let(:exec) {double('Execute').as_null_object}
  let(:scan) {ScanDiscCdinfo.new(prefs, exec)}

  before(:each) do
    prefs.should_receive(:cdrom).at_least(:once).and_return('/dev/cdrom')
  end

  def setQueryReply(answer)
    exec.should_receive(:launch).with('cd-info -C /dev/cdrom -A --no-cddb').and_return(answer)
  end

  context "When a queryresult is not a valid response" do
    it "should detect if cd-info is not installed" do
      setQueryReply(nil)
      scan.scan()
      scan.status.should == 'notInstalled'
    end

    it "should detect if the drive is not valid" do
      setQueryReply('PARTICULAR PURPOSE.\n++ WARN: Can\'t get file status for')
      scan.scan()
      scan.status.should == 'unknownDrive'
    end

    it "should detect a problem with parameters" do
      setQueryReply('cd-info: unrecognized option \'--unknownArgument\'\nUsage: cd')
      scan.scan()
      scan.status.should == 'wrongParameters'
    end

    it "should detect if there is no disc inserted" do
      setQueryReply('Disc mode is listed as: Error in getting information\n\
++ WARN: error in ioctl CDROMREADTOCHDR: No medium found')
      scan.scan()
      scan.status.should == 'noDiscInDrive'
    end
  end

  context "When a query is a valid response" do
    it "should detect the cd-info version" do
      setQueryReply("cd-info version 0.82 i686-pc-linux-gnu\nCopyright (c) 2003")
      scan.scan()
      scan.status.should == 'ok'
      scan.version.should == 'cd-info version 0.82 i686-pc-linux-gnu'
    end

    it "should detect the discmode of the drive" do
      setQueryReply("___________\n\nDisc mode is listed as: CD-DA")
      scan.scan()
      scan.discMode.should == 'CD-DA'
    end

    it "should detect the devicename for the drive" do
      setQueryReply("Vendor                      : HL-DT-ST\nModel                      \
: DVDRAM GH22NS40\nRevision                    : NL01")
      scan.scan()
      scan.deviceName.should == 'HL-DT-ST DVDRAM GH22NS40 NL01'
    end

    it "should detect the startsector for each track" do
      setQueryReply(" 15: 36:34:45  164445 audio  false  no    2        no\n 16: 39:55:60  \
179535 audio  false  no    2        no\n170: 43:33:30  195855 leadout")
      scan.scan()
      scan.getStartSector(14).should == nil
      scan.getStartSector(15).should == 164445
      scan.getStartSector(16).should == 179535
      scan.getStartSector(17).should == nil
    end

    it "should detect the length in sectors for each track" do
      setQueryReply(" 15: 36:34:45  164445 audio  false  no    2        no\n 16: 39:55:60  \
179535 audio  false  no    2        no\n170: 43:33:30  195855 leadout")
      scan.scan()
      scan.getLengthSector(14).should == nil
      scan.getLengthSector(15).should == 15090
      scan.getLengthSector(16).should == 16320
      scan.getLengthSector(17).should == nil
    end

    it "should detect the length in mm:ss for each track" do
      setQueryReply(" 15: 36:34:45  164445 audio  false  no    2        no\n 16: 39:55:60  \
179535 audio  false  no    2        no\n170: 43:33:30  195855 leadout")
      scan.scan()
      scan.getLengthText(14).should == nil
      scan.getLengthText(15).should == '03:21.15'
      scan.getLengthText(16).should == '03:37.45'
      scan.getLengthText(17).should == nil
    end

    it "should detect the total amount of sectors for the disc" do
      setQueryReply("       no\n170: 43:33:30  195855 leadout")
      scan.scan()
      scan.totalSectors.should == 195855
    end

    it "should detect the playtime in mm:ss for the disc" do
      setQueryReply("       no\n170: 43:33:30  195855 leadout")
      scan.scan()
      scan.playtime.should == '43:31' #minus 2 seconds offset, without frames
    end

    it "should detect the amount of audiotracks" do
     setQueryReply(" 15: 36:34:45  164445 audio  false  no    2        no\n 16: 39:55:60  \
179535 audio  false  no    2        no\n170: 43:33:30  195855 leadout")
      scan.scan()
      scan.audiotracks.should == 2
    end

    it "should detect the first audio track" do
      setQueryReply(" 15: 36:34:45  164445 audio  false  no    2        no\n 16: 39:55:60  \
179535 audio  false  no    2        no\n170: 43:33:30  195855 leadout")
      scan.scan()
      scan.firstAudioTrack.should == 15
    end

    it "should detect if there are no data tracks on the disc" do
      setQueryReply(" 15: 36:34:45  164445 audio  false  no    2        no\n 16: 39:55:60  \
179535 audio  false  no    2        no\n170: 43:33:30  195855 leadout")
      scan.scan()
      scan.audiotracks.should == 2
      scan.dataTracks.should == []
      scan.tracks.should == 2
    end

    it "should detect the data tracks on the disc" do
      setQueryReply(" 13: 61:11:22  275197 data   false  no\n170: 73:47:31  \
331906 leadout (744 MB raw, 744 MB formatted)")
      scan.scan()
      scan.audiotracks.should == 0
      scan.dataTracks.should == [13]
      scan.tracks.should == 1
    end
  end
end
