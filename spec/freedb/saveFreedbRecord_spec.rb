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

require 'rubyripper/metadata/freedb/saveFreedbRecord'

describe SaveFreedbRecord do

  before(:all) do
    @record = 'record with the complete freedb string'
    @category = 'a sample freedb music category like blues'
    @discid = 'the id for a disc calculated as a hexadecimal number'
    @filename = File.join(ENV['HOME'], '.cddb', @category, @discid)
  end

  it "should save the provided record in a file at the right location" do
    file = double('fileAndDir')
    file.should_receive(:write).with(@filename, @record, false).and_return('ok')
    save = SaveFreedbRecord.new(file)

    save.save(@record, @category, @discid)
    save.outputFile.should == @filename
  end

  it "shouldn't overwrite existing files but still save the filename" do
    file = double('fileAndDir')
    file.should_receive(:write).exactly(1).times.and_return('fileExists')

    save = SaveFreedbRecord.new(file)
    save.save(@record, @category, @discid)
    save.outputFile.should == @filename
	end
end
