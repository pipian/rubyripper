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

require 'rubyripper/metadata/data'
require 'rubyripper/metadata/filter/filterDirs'

describe Metadata::FilterDirs do
  
  let(:data) {Metadata::Data.new()}
  let(:prefs) {double('Preferences').as_null_object}
  let(:filter) {Metadata::FilterDirs.new(data, prefs)}
  
  before(:each) do
    prefs.stub!(:noSpaces).and_return false
    prefs.stub!(:noCapitals).and_return false
  end
  
  context "Plus it should filter out any conflicting characters for the FAT filesystem" do
    it "should replace the dollar sign $" do
      data.artist = 'I like CA$H'
      filter.artist.should == 'I like CASH'
    end
    
    it "should remove colons :" do
      data.artist = 'Hello: world'
      filter.artist.should == 'Hello world'
    end
    
    it "should remove asterixes *" do
      data.artist = 'Hello* world'
      filter.artist.should == 'Hello world'
    end
    
    it "should remove question marks ?" do
      data.artist = 'Hello? world'
      filter.artist.should == 'Hello world'
    end
    
    it "should remove smaller than signs <" do
      data.artist = 'Hello< world'
      filter.artist.should == 'Hello world'
    end
    
    it "should remove bigger than signs >" do
      data.artist = 'Hello> world'
      filter.artist.should == 'Hello world'
    end
    
    it "should remove the pipe character |" do
      data.artist = 'Hello| world'
      filter.artist.should == 'Hello world'
    end
    
    it "should remove backslashes \\" do
      data.artist = 'Hello\\ world'
      filter.artist.should == 'Hello world'
    end
    
    it "should remove double quotes \"" do
      data.artist = 'Hello" world'
      filter.artist.should == "Hello world"
    end
    
    it "should be able to combine all logic for filterDirs + filterAll" do
      data.tracklist = {1=>"  \"\\Don`t_won\342\200\230t_know ??_** >< | "}
      filter.trackname(1).should == "Don't won't know"
    end
  end
  
  context "Replace any characters that are not wished by the user" do
    it "should replace all spaces to underscores if wished for" do
      data.artist = 'Hello world'
      prefs.stub!(:noSpaces).and_return true
      filter.artist.should == "Hello_world"
    end
    
    it "should downsize all letters if wished for" do
      data.artist = 'hELLo WoRLD'
      prefs.stub!(:noCapitals).and_return true
      filter.artist.should == 'hello world'
    end
  end
end