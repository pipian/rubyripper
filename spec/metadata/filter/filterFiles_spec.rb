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
require 'rubyripper/metadata/filter/filterFiles'

describe Metadata::FilterFiles do
  
  let(:prefs) {double('Preferences').as_null_object}
  let(:filter) {Metadata::FilterFiles.new(nil, prefs)}
  
  before(:each) do
    prefs.stub!(:noSpaces).and_return false
    prefs.stub!(:noCapitals).and_return false
  end
  
  context "When determining the filename it has to be valid" do
    it "should replace the slash sign /" do
      data.artist = 'AC/DC'
      filter.artist.should == 'ACDC'
    end
    
    it "should be able to combine all logic for filterFiles + filterDirs + filterAll" do
      data.tracklist = {1=>" AC/DC \"\\Don`t_won\342\200\230t_know ??_** >< | "}
      filter.trackname(1).should == "ACDC Don't won't know"
    end
  end
end