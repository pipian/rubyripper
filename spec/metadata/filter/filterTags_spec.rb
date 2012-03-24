#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012 Bouke Woudstra (boukewoudstra@gmail.com)
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
require 'rubyripper/metadata/filter/filterTags'

describe Metadata::FilterTags do
  
  let(:data) {Metadata::Data.new()}
  let(:prefs) {double('Preferences').as_null_object}
  let(:filter) {Metadata::FilterTags.new(data, prefs)}
  
  before(:each) do
    prefs.stub!(:noSpaces).and_return false
    prefs.stub!(:noCapitals).and_return false
  end
  
  context "When determining the tag it should be valid when passing the command" do
    it "should always return any tag with quotes around it to cover spaces" do
      data.artist = "Iron maiden"
      filter.artist.should == '"Iron maiden"'
    end
    
    it "should escape the double quote" do
      data.artist = 'abc"def'
      filter.artist.should == '"abc\\"def"' # in a terminal this becomes abc\"def
    end
    
    it "should be able to combine all logic for filterTags + filterAll" do
      data.tracklist = {1=>" #{'abc"def'} AC/DC Don`t_wont_know ??_** >< | "}
      filter.trackname(1).should == "\"#{'abc\\"def'} AC/DC Don't wont know ?? ** >< |\""
    end
  end
end