#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/disc/disc'

describe Disc do
  
  let(:cdpar) {double('ScanDiscCdparanoia').as_null_object}
  let(:freedb) {double('FreedbString').as_null_object}
  let(:musicbrainz) {double('CalcMusicbrainzID').as_null_object}
  let(:deps) {double('Dependency').as_null_object}
  let(:prefs) {double('Preferences').as_null_object}
  let(:metadata) {double('Freedb').as_null_object}
  let(:disc) {Disc.new(cdpar, freedb, musicbrainz, deps, prefs)}
  
  context "When a disc is requested to be scanned" do
    before(:each) do
      cdpar.should_receive(:scan).once().and_return true
    end
    
    it "should send the scan command to cdparanoia" do
      cdpar.should_receive(:status).once().and_return false
      disc.scan()
    end
    
    it "should trigger the metadata class if a disc is found" do
      cdpar.should_receive(:status).once().and_return 'ok'
      metadata.should_receive(:get).once().and_return 1
      disc.scan(metadata)
      disc.metadata.should == 1
    end
    
    it "should not trigger the metadata if no disc is found" do
      cdpar.should_receive(:status).once().and_return false
      metadata.should_not_receive(:get)
      disc.scan(nil)
      disc.metadata.should == nil
    end
  end
  
  context "When a toc analyzer is requested for calculating the disc id" do
    it "should first refer to the cd-info scanner if it is installed" do
      deps.should_receive(:installed?).with('cd-info').and_return true
      disc.advancedTocScanner(cdinfo='a', cdcontrol='b').should == 'a'
    end
    
    it "should then refer to the cdcontrol scanner if it is installed" do
      deps.should_receive(:installed?).with('cd-info').and_return false
      deps.should_receive(:installed?).with('cdcontrol').and_return true
      disc.advancedTocScanner(cdinfo='a', cdcontrol='b').should == 'b'
    end
    
    it "should fall back to cdparanoia if nothing better is available" do
      deps.should_receive(:installed?).with('cd-info').and_return false
      deps.should_receive(:installed?).with('cdcontrol').and_return false
      disc.advancedTocScanner(cdinfo='a', cdcontrol='b').should == cdpar
    end
  end
  
  context "When methods need to be forwarded" do
    it "should forward the freedbstring method to the calcFreedbID object" do
      freedb.should_receive(:freedbString).once.and_return true
      disc.freedbString()
    end
    
    it "should forward the freedb discid method to the calcFreedbID object" do
      freedb.should_receive(:discid).once.and_return true
      disc.freedbDiscid()
    end
    
    it "should forward the musicbrainzlookuppath method to the calcMusicbrainzID object" do
      musicbrainz.should_receive(:musicbrainzLookupPath).once.and_return true
      disc.musicbrainzLookupPath()
    end
    
    it "should forward the musicbrainzdiscid method to the calcMusicbrainzID object" do
      musicbrainz.should_receive(:discid).once.and_return true
      disc.musicbrainzDiscid()
    end
    
    # all unknown commands should be redirected to cdparanoia
    it "should pass any other command to cdparanoia" do
      cdpar.should_receive(:any_other_command).and_return true
      disc.any_other_command()
    end
  end
end
