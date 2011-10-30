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

require 'rubyripper/system/dependency'

describe Dependency do
  let(:file) {double('File').as_null_object}
  before(:each) {file.stub("exist?").and_return(false)}
    
  context "When searching for the disc drive on freebsd" do
    let(:deps) {Dependency.new(file, platform='freebsd')}
    
    it "should query the device on /dev/cd# for existence" do
      (0..9).each{|num| file.should_receive("exist?").with("/dev/cd#{num}").and_return(false)}
      deps.cdrom().should == "unknown"
    end
    
    it "should query the device on /dev/acd# for existence" do
      (0..9).each{|num| file.should_receive("exist?").with("/dev/acd#{num}").and_return(false)}
      deps.cdrom().should == "unknown"
    end
    
    it "should detect a drive on /dev/cd0" do
      file.should_receive("exist?").with("/dev/cd0").and_return(true)   
      deps.cdrom().should == '/dev/cd0'
    end
    
    it "should detect a drive on /dev/cd9" do
      file.should_receive("exist?").with("/dev/cd9").and_return(true)
      deps.cdrom().should == '/dev/cd9'
    end
    
    it "should detect a drive on /dev/acd0" do
      file.should_receive("exist?").with("/dev/acd0").and_return(true)
      deps.cdrom().should == '/dev/acd0'
    end
    
    it "should detect a drive on /dev/acd9" do
      file.should_receive("exist?").with("/dev/acd9").and_return(true)
      deps.cdrom().should == '/dev/acd9'
    end
  end
  
  context "When searching for the disc drive on linux" do
    let(:deps) {Dependency.new(file, platform='linux')}
    
    it "should detect a drive on /dev/cdrom" do
      file.should_receive("exist?").with("/dev/cdrom").and_return(true)   
      deps.cdrom().should == '/dev/cdrom'
    end
    
    it "should detect a drive on /dev/dvdrom" do
      file.should_receive("exist?").with("/dev/dvdrom").and_return(true)   
      deps.cdrom().should == '/dev/dvdrom'
    end
    
    it "should query the device on /dev/sr# for existence" do
      (0..9).each{|num| file.should_receive("exist?").with("/dev/sr#{num}").and_return(false)}
      deps.cdrom().should == "unknown"
    end
    
    it "should detect a drive on /dev/sr0" do
      file.should_receive("exist?").with("/dev/sr0").and_return(true)   
      deps.cdrom().should == '/dev/sr0'
    end
    
    it "should detect a drive on /dev/sr9" do
      file.should_receive("exist?").with("/dev/sr9").and_return(true)   
      deps.cdrom().should == '/dev/sr9'
    end
  end
end