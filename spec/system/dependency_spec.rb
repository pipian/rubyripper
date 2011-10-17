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

describe Dependency do
  let(:file) {double('FileAndDir').as_null_object}
  
  context "When searching for the disc drive on freebsd" do
    let(:deps) {Dependency.new(file, platform='freebsd')}
    
    it "should query the device on /dev/cd# for existence" do
      (0..9).each{|num| file.should_receive("exist?").with("/dev/cd#{num}").and_return(false)}
      file.stub("exist?").and_return(false)
      deps.cdrom().should == "unknown"
    end
    
    it "should query the device on /dev/acd# for existence" do
      (0..9).each{|num| file.should_receive("exist?").with("/dev/acd#{num}").and_return(false)}
      file.stub("exist?").and_return(false)
      deps.cdrom().should == "unknown"
    end
    
    it "should detect a drive on /dev/cd0" do
      file.should_receive("exist?").with("/dev/cd0").and_return(true)
      file.stub("exist?").and_return(false)
      deps.cdrom().should == '/dev/cd0'
    end
    
    it "should detect a drive on /dev/cd9" do
      file.should_receive("exist?").with("/dev/cd9").and_return(true)
      file.stub("exist?").and_return(false)
      deps.cdrom().should == '/dev/cd9'
    end
    
    it "should detect a drive on /dev/acd0" do
      file.should_receive("exist?").with("/dev/acd0").and_return(true)
      file.stub("exist?").and_return(false)
      deps.cdrom().should == '/dev/acd0'
    end
    
    it "should detect a drive on /dev/acd9" do
      file.should_receive("exist?").with("/dev/acd9").and_return(true)
      file.stub("exist?").and_return(false)
      deps.cdrom().should == '/dev/acd9'
    end
  end
end