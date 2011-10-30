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

require 'rubyripper/disc/disc'

describe Disc do
  
  let(:cdpar) {double('ScanDiscCdparanoia').as_null_object}
  let(:freedb) {double('FreedbString').as_null_object}
  let(:deps) {double('Dependency').as_null_object}
  let(:metadata) {double('Freedb').as_null_object}
  let(:disc) {Disc.new(cdpar, freedb, deps)}
  
  context "When a disc is requested to be scanned" do
    before(:each) do
      cdpar.should_receive(:scan).once().and_return true
    end
    
    it "should send the scan command to cdparanoia" do
      cdpar.should_receive(:status).once().and_return false
      disc.scan()
    end
    
    it "should trigger the metadata if a disc is found" do
      cdpar.should_receive(:status).once().and_return 'ok'
      metadata.should_receive(:get).once().and_return true
      disc.scan(metadata)
    end
    
    it "should not trigger the metadata if no disc is found" do
      cdpar.should_receive(:status).once().and_return false
      metadata.should_not_receive(:get)
      disc.scan(nil)
    end
  end
  
  context "When a toc analyzer is requested for calculating the freedb string" do
    it "should first refer to the cd-info scanner if it is installed" do
      deps.should_receive(:installed?).with('cd-info').and_return true
      disc.tocScannerForFreedbString(cdinfo='a', cdcontrol='b').should == 'a'
    end
    
    it "should then refer to the cdcontrol scanner if it is installed" do
      deps.should_receive(:installed?).with('cd-info').and_return false
      deps.should_receive(:installed?).with('cdcontrol').and_return true
      disc.tocScannerForFreedbString(cdinfo='a', cdcontrol='b').should == 'b'
    end
    
    it "should fall back to cdparanoia if nothing better is available" do
      deps.should_receive(:installed?).with('cd-info').and_return false
      deps.should_receive(:installed?).with('cdcontrol').and_return false
      disc.tocScannerForFreedbString(cdinfo='a', cdcontrol='b').should == cdpar
    end
  end
  
  context "When methods need to be forwarded" do
    it "should forward the freedbstring method to the freedbstring object" do
      freedb.should_receive(:freedbString).once.and_return true
      disc.freedbString()
    end
    
    it "should forward the discid method to the freedbstring object" do
      freedb.should_receive(:discid).once.and_return true
      disc.discid()
    end
    
    # all unknown commands should be redirected to cdparanoia
    it "should pass any other command to cdparanoia" do
      cdpar.should_receive(:any_other_command).and_return true
      disc.any_other_command()
    end
  end
end