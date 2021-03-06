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

require 'rubyripper/disc/scanDiscCdparanoia'

describe ScanDiscCdparanoia do

  def setQueryReply(reply, command=nil)
    prefs.stub('testdisc').and_return false
    command ||= 'cdparanoia -d /dev/cdrom -vQ'
    exec.stub(:launch).with(command).and_return reply
  end

  let(:exec) {double('Execute').as_null_object}
  let(:perm) {double('PermissionDrive').as_null_object}
  let(:prefs) {double('Preferences').as_null_object}
  let(:disc) {ScanDiscCdparanoia.new(exec, perm, prefs)}

  context "Before scanning any disc" do
    it "shouldn't set default values" do
      disc.status.should == nil
      disc.playtime.should == nil
      disc.audiotracks.should == nil
      disc.devicename.should == nil
      disc.firstAudioTrack.should == nil
    end

    it "should raise an error when a function other than scan() is called" do
      lambda{disc.getStartSector(1)}.should raise_error(RuntimeError, /getStartSector/)
      lambda{disc.getLengthSector(1)}.should raise_exception(RuntimeError, /getLengthSector/)
      lambda{disc.getLengthText(1)}.should raise_exception(RuntimeError, /getLengthText/)
      lambda{disc.getFileSize(1)}.should raise_exception(RuntimeError, /getFileSize/)
      lambda{disc.getStartSector('image')}.should raise_exception(RuntimeError, /getStartSector/)
      lambda{disc.getLengthSector('image')}.should raise_exception(RuntimeError, /getLengthSector/)
      lambda{disc.getLengthText('image')}.should raise_exception(RuntimeError, /getLengthText/)
      lambda{disc.getFileSize('image')}.should raise_exception(RuntimeError, /getFileSize/)
    end
  end

  context "When trying to scan a disc" do
    before(:each) do
      prefs.should_receive(:cdrom).at_least(:once).and_return('/dev/cdrom')
      perm.should_receive(:problems?).once.and_return(false)
    end

    it "should abort when cdparanoia is not installed" do
      setQueryReply(nil)
      disc.scan()
      disc.status.should == 'error'
      disc.error.should == [:notInstalled, 'cdparanoia']
    end
    
    it "should abort when cdparanoia is unable to open the disc" do
      setQueryReply(["Unable to open disc.  Is there an audio CD in the drive?"])
      disc.scan()
      disc.status.should == 'error'
      disc.error.should == [:noDiscInDrive, '/dev/cdrom']
    end

    it "should have one retry without the drive parameter when cdparanoia doesn't recognize it"  do
      setQueryReply(["USAGE:"])
      setQueryReply(["USAGE:"], 'cdparanoia -vQ')
      disc.scan()
      disc.status.should == 'error'
      disc.error.should == [:wrongParameters, 'cdparanoia']
    end

    it "should abort when the disc drive is not found" do
      setQueryReply(["Could not stat /dev/cdrom: No such file or directory"])
      disc.scan()
      disc.status.should == 'error'
      disc.error.should == [:unknownDrive, '/dev/cdrom']
    end
  end

  context "When a disc is found" do
    before(:each) do
      @cdparanoia ||= File.read('spec/disc/data/cdparanoia').split("\n")
      perm.should_receive(:problems?).once.and_return(false)
      perm.should_receive(:problemsSCSI?).once.and_return(false)
      prefs.should_receive(:cdrom).at_least(:once).and_return('/dev/cdrom')
    end

    it "should set the status to ok" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.status.should == 'ok'
    end

    it "should save the playtime in minutes:seconds" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.playtime.should == '36:12'
    end

    it "should save the amount of audiotracks" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.audiotracks.should == 10
    end

    it "should detect the devicename" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.devicename.should == 'HL-DT-ST DVDRAM GH22NS40 NL01'
    end

    it "should detect the first track" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.firstAudioTrack.should == 1
    end

    it "should return the startsector for a track" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.getStartSector(0).should == nil
      disc.getStartSector(1).should == 0
      disc.getStartSector(10).should == 124080
      disc.getStartSector(11).should == nil
    end

    it "should return the amount of sectors for a track" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.getLengthSector(0).should == nil
      disc.getLengthSector(1).should == 13209
      disc.getLengthSector(10).should == 38839
      disc.getLengthSector(11).should == nil
    end

    it "should return the length in mm:ss for a track" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.getLengthText(0).should == nil
      disc.getLengthText(1).should == '02:56'
      disc.getLengthText(10).should == '08:37'
      disc.getLengthText(11).should == nil
    end

    it "should return the filesize in bytes for a track" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.getFileSize(0).should == nil
      disc.getFileSize(1).should == 31067612
      disc.getFileSize(10).should == 91349372
      disc.getFileSize(11).should == nil
    end
    
    it "should serve image ripping as well" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.getStartSector(nil).should == 0
      disc.getLengthSector(nil).should == 162919
      disc.getLengthText(nil).should == '36:12'
      disc.getFileSize(nil).should == 383185532
    end

    it "should detect the total sectors of the disc" do
      setQueryReply(@cdparanoia)
      disc.scan()
      disc.totalSectors.should == 162919
    end
  end
end
