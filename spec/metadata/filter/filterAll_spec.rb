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
require 'rubyripper/metadata/filter/filterAll'

describe Metadata::FilterAll do
  
  let(:data) {Metadata::Data.new()}
  let(:prefs) {double('Preferences').as_null_object}
  let(:filter) {Metadata::FilterAll.new(data, prefs)}
 
  context "The filter should return all values of metadata" do  
    it "should remove a backquote and replace it with a single quote" do
      data.artist = 'No ` allowed'
      filter.artist.should == "No ' allowed"
    end
    
    it "should replace underscores with spaces if noSpaces setting = false" do
      data.artist = 'Iron_Maiden'
      prefs.should_receive(:noSpaces).and_return false
      filter.artist.should == 'Iron Maiden'
    end
    
    it "should keep the underscores if noSpaces setting = true" do
      data.artist = 'Iron_Maiden'
      prefs.should_receive(:noSpaces).and_return true
      filter.artist.should == 'Iron_Maiden'
    end
    
    it "should replace UTF-8 single quote with ASCII single quote" do
      data.artist = "single quote \342\200\230 1"
      data.album = "single quote \342\200\231 2"
      filter.artist.should == "single quote ' 1"
      filter.album.should == "single quote ' 2"
    end
    
    it "should replace UTF-8 double quote with ASCII double quote" do
      data.artist = "double quote \342\200\234 1"
      data.album = "double quote \342\200\235 2"
      filter.artist.should == 'double quote " 1'
      filter.album.should == 'double quote " 2'
    end
    
    it "should strip extra spaces" do
      data.artist = '  Random artist   '
      filter.artist.should == 'Random artist'
    end
    
    it "should be able to combine this logic" do
      data.tracklist = {1=>"  Don`t_won\342\200\230t_know  "}
      prefs.should_receive(:noSpaces).and_return false
      filter.trackname(1).should == "Don't won't know"
    end
  end
end