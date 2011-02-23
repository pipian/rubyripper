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

describe FreedbString do

  let(:deps) {double('Dependency').as_null_object}
  let(:prefs) {double('Preferences').as_null_object}
  let(:scan) {double('ScanDiscCdparanoia').as_null_object}
  let(:fire) {double('FireCommand').as_null_object}
  let(:cdinfo) {double('ScanDiscCdinfo').as_null_object}

  before(:each) do
    @freedb = FreedbString.new(deps, prefs, scan, fire, cdinfo)
    @freedbString = "7F087C0A 10 150 13359 36689 53647 68322 81247 87332 \
106882 122368 124230 2174"
    prefs.stub(:get).with('cdrom').and_return('/dev/cdrom')
    prefs.stub(:get).with('debug').and_return false
    deps.stub(:platform).and_return('i686-linux')
  end

  context "When a help program for creating a freedbstring exists" do
    it "should first try to use discid" do
      deps.stub(:get).with('discid').exactly(1).times.and_return true
      fire.stub(:launch).with('discid /dev/cdrom').and_return @freedbString
      @freedb.get()

      @freedb.freedbString.should == @freedbString
      @freedb.discid.should == "7F087C0A"
    end

    it "should then try to use cd-discid" do
      deps.stub(:get).with('discid').exactly(1).times.and_return false
      deps.stub(:get).with('cd-discid').exactly(1).times.and_return true
      fire.stub(:launch).with('cd-discid /dev/cdrom').and_return @freedbString
      @freedb.get()

      @freedb.freedbString.should == @freedbString
      @freedb.discid.should == "7F087C0A"
    end

    context "When the platform is DARWIN (a.k.a. OS X)" do
      it "should unmount the disc properly and mount it afterwards" do
        deps.stub(:platform).and_return('i686-darwin')
        deps.stub(:get).with('discid').exactly(1).times.and_return true
        fire.stub(:launch).with('diskutil unmount /dev/cdrom').exactly(1).times
        fire.stub(:launch).with('discid /dev/cdrom').and_return @freedbString
        fire.stub(:launch).with('diskutil mount /dev/cdrom').exactly(1).times
        @freedb.get()

        @freedb.freedbString.should == @freedbString
        @freedb.discid.should == "7F087C0A"
      end
    end
  end

  context "When no help program exists, try to do it ourselves" do
    before(:each) do
      @start = {1=>0, 2=>13209, 3=>36539, 4=>53497, 5=>68172, 6=>81097,
7=>87182, 8=>106732, 9=>122218, 10=>124080}
      @length = {1=>13209, 2=>23330, 3=>16958, 4=>14675, 5=>12925,
6=>6085, 7=>19550, 8=>15486, 9=>1862, 10=>38839}
      deps.stub(:get).with('discid').exactly(1).times.and_return false
      deps.stub(:get).with('cd-discid').exactly(1).times.and_return false
      scan.stub(:get).with('startSector').exactly(1).times.and_return @start
      scan.stub(:get).with('lengthSector').exactly(1).times.and_return @length
    end

    it "should try to read values from cd-info, but skip to cdparanoia" do
      deps.stub(:get).with('cd-info').and_return false
      @freedb.get()

      @freedb.freedbString.should == @freedbString
      @freedb.discid.should == "7F087C0A"
    end

    it "should read cd-info values when possible" do
      deps.stub(:get).with('cd-info').and_return true
      cdinfo.stub(:scan).and_return true
      cdinfo.stub(:status).and_return 'ok'
      cdinfo.stub(:get).with('startSector').exactly(1).times.and_return @start
      cdinfo.stub(:get).with('lengthSector').exactly(1).times.and_return @length
      cdinfo.stub(:get).with('tracks').exactly(1).times.and_return 10
      @freedb.get()

      @freedb.freedbString.should == @freedbString
      @freedb.discid.should == "7F087C0A"
    end
  end
end