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
  let(:fire) {double('FireCommand').as_null_object}
  let(:scan) {ScanDiscCdinfo.new(prefs, fire)}

  before(:each) do
    prefs.should_receive(:get).with('cdrom').at_least(:once).and_return('/dev/cdrom')
  end

  context "When a queryresult is not a valid response" do
    it "should detect if cd-info is not installed" do
      answer = nil
      fire.should_receive(:launch).with('cd-info -C /dev/cdrom').and_return(answer)
      scan.scan()
      scan.status.should == 'notInstalled'
    end

    it "should detect if the drive is not valid" do
      answer = 'PARTICULAR PURPOSE.\n++ WARN: Can\'t get file status for'
      fire.should_receive(:launch).with('cd-info -C /dev/cdrom').and_return(answer)
      scan.scan()
      scan.status.should == 'unknownDrive'
    end

    it "should detect a problem with parameters" do
      answer = 'cd-info: unrecognized option \'--unknownArgument\'\nUsage: cd'
      fire.should_receive(:launch).with('cd-info -C /dev/cdrom').and_return(answer)
      scan.scan()
      scan.status.should == 'wrongParameters'
    end

    it "should detect if there is no disc inserted" do
      answer = 'Disc mode is listed as: Error in getting information\n\
++ WARN: error in ioctl CDROMREADTOCHDR: No medium found'
      fire.should_receive(:launch).with('cd-info -C /dev/cdrom').and_return(answer)
      scan.scan()
      scan.status.should == 'noDiscInDrive'
    end
  end

  context "When a query is a valid response" do
    it "should detect the cd-info version"
    it "should detect the vendor of the drive"
    it "should detect the model of the drive"
    it "should detect the revision of the drive"
    it "should detect the discmode of the drive"
    it "should detect the startsector for each track"
    it "should detect the data tracks on the disc"
    it "should detect the total amount of sectors for the disc"
    it "should detect the playtime in mm:ss for the disc"
    it "should detect the complete drivename"
    it "should detect the amount of audiotracks"
    it "should detect the first audio track"
    it "should detect the length in sectors for each track"
    it "should detect the length in mm:ss for each track"
  end
end