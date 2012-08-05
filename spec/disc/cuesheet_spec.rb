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

class DiscStub
  attr_accessor :startSectors
  attr_reader :metadata, :freedbDiscid, :freedbString, :audiotracks
  
  def initialize
    @freedbDiscid = 'AAAA1234'
    @freedbString = 'This is a freedb string'
    @metadata = MetadataStub.new()
    @audiotracks = 3
    @startSectors = {1=>0, 2=>225, 3=>450}
  end
  
  def getStartSector(track) ; @startSectors[track] ; end
end

class MetadataStub
  attr_reader :genre, :year, :artist, :album
  
  def initialize
    @genre = 'rock'
    @year = '1983'
    @artist = 'Iron Maiden'
    @album = 'Number of the Beast'
  end
  
  def various? ; false ; end 
  def getTrackname(track) ; "Title track #{track}" ; end
end

describe Cuesheet do

  let(:disc) {DiscStub.new()}
  let(:cdrdao) {double('ScanDiscCdrdao').as_null_object}
  let(:fileScheme) {double('FileScheme').as_null_object}
  let(:fileAndDir) {double('FileAndDir').as_null_object}
  let(:prefs) {double('Preferences::Main').as_null_object}
  let(:deps) {double('Dependency').as_null_object}
  let(:cue) {Cuesheet.new(disc, cdrdao, fileScheme, fileAndDir, prefs, deps)}

  it "should show all relevant disc data at the top" do
    cue.test_printDiscData()
    cue.cuesheet.should == ['REM GENRE rock', 'REM DATE 1983', 'REM DISCID AAAA1234',
                            'REM FREEDB_QUERY "This is a freedb string"', 'REM COMMENT "Rubyripper test"',
                            'PERFORMER "Iron Maiden"', 'TITLE "Number of the Beast"']
  end
  
  context "When printing the track info for image rips" do
    
    before(:each) do
      @cuesheet = ['FILE "image_rip.flac" WAVE', 
                   '  TRACK 01 AUDIO', '    TITLE "Title track 1"', 
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00',
                   '  TRACK 02 AUDIO', '    TITLE "Title track 2"', 
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:03:00',
                   '  TRACK 03 AUDIO', '    TITLE "Title track 3"', 
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:06:00']
      fileScheme.should_receive(:getFile).and_return '/home/test/image_rip.flac'
    end
    
    it "should handle the default case for a disc correctly" do
      cdrdao.stub!(:getPregapSectors).and_return 0
      cue.test_printTrackDataImage('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should write a zero index if hidden audio before track 1 is ripped" do
      prefs.stub!(:ripHiddenAudio).and_return true
      disc.startSectors[1] = 100
      cdrdao.stub!(:getPregapSectors).and_return 0
      @cuesheet.insert(4, '    INDEX 00 00:00:00')
      @cuesheet[5] = '    INDEX 01 00:01:25'
      cue.test_printTrackDataImage('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should write a pregap tag if hidden audio before track 1 is not ripped" do
      prefs.stub!(:ripHiddenAudio).and_return false
      disc.startSectors[1] = 100
      cdrdao.stub!(:getPregapSectors).and_return 0
      @cuesheet.insert(2, '  PREGAP 00:01:25')
      cue.test_printTrackDataImage('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should write a zero index for tracks > 1 with a pregap" do
      prefs.stub!(:ripHiddenAudio).and_return true
      cdrdao.stub!(:getPregapSectors).and_return 0
      cdrdao.stub!(:getPregapSectors).with(2).and_return 100
      @cuesheet.insert(8, '    INDEX 00 00:03:00')
      @cuesheet[9] = '    INDEX 01 00:04:25'
      cue.test_printTrackDataImage('flac')
      cue.cuesheet.should == @cuesheet
    end
  end
end
