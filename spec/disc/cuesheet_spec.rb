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

require 'rubyripper/disc/cuesheet'

describe Cuesheet do

  let(:disc) {double('Disc').as_null_object}
  let(:md) {double('Metadata').as_null_object}
  let(:cdrdao) {double('ScanDiscCdrdao').as_null_object}
  let(:fileScheme) {double('FileScheme').as_null_object}
  let(:fileAndDir) {double('FileAndDir').as_null_object}
  let(:prefs) {double('Preferences::Main').as_null_object}
  let(:deps) {double('Dependency').as_null_object}
  let(:cue) {Cuesheet.new(disc, cdrdao, fileScheme, fileAndDir, prefs, deps)}
  
  before(:each){disc.stub!(:metadata).and_return(md)}

  it "should show all relevant disc data at the top" do
    md.should_receive(:genre).and_return('rock')
    md.should_receive(:year).and_return('1983')
    disc.should_receive(:freedbDiscid).and_return('AAAA1234')
    disc.should_receive(:freedbString).and_return('a freedb string')
    md.should_receive(:artist).and_return('Iron Maiden')
    md.should_receive(:album).and_return('The number of the beast')
    cue.test_printDiscData()
    cue.cuesheet.should == ['REM GENRE rock', 'REM DATE 1983', 'REM DISCID AAAA1234',
                            'REM FREEDB_QUERY a freedb string', 'REM COMMENT Rubyripper test',
                            'PERFORMER Iron Maiden', 'TITLE The number of the beast']
  end
  
#  context "Given track ripping is active (instead of image ripping)" do
#    before(:each) do
#      disc.stub(:audiotracks).and_return 3
#    end
    
#    it "should write the TRACK tag from track 1 until last audio track" do
#      @disc.should_receive(:getStartSector).with(0).and_return true
#      cue.test_printTrackData('wav')
#      cue.cuesheet.should include "TRACK 01 AUDIO"
#      cue.cuesheet.should include "TRACK 02 AUDIO"
#      cue.cuesheet.should include "TRACK 03 AUDIO"
#      cue.cuesheet.should_not include "TRACK 00 AUDIO"
#      cue.cuesheet.should_not include "TRACK 04 AUDIO"
#    end
#  end
end

