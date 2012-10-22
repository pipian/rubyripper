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
    @lengthSectors = {1=>225, 2=>225, 3=>225}
  end
  
  def getStartSector(track) ; @startSectors[track] ; end
  def getLengthSector(track) ; @lengthSectors[track] ; end
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
  def trackname(track) ; "Title track #{track}" ; end
end

class FileAndDirStub
  def getFile(codec, track)
    track == nil ? '/home/test/Image_rip.flac' : "/home/test/Track_#{track}.flac"
  end
end

# A nice source for info is http://wiki.hydrogenaudio.org/index.php?title=EAC_and_Cue_Sheets
describe Cuesheet do

  let(:disc) {DiscStub.new()}
  let(:cdrdao) {double('ScanDiscCdrdao').as_null_object}
  let(:fileScheme) {FileAndDirStub.new()}
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
      @cuesheet = ['FILE "Image_rip.flac" WAVE', 
                   '  TRACK 01 AUDIO', '    TITLE "Title track 1"', 
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00',
                   '  TRACK 02 AUDIO', '    TITLE "Title track 2"', 
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:03:00',
                   '  TRACK 03 AUDIO', '    TITLE "Title track 3"', 
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:06:00']
    end
    
    it "should handle the default case for a disc correctly" do
      cdrdao.stub!(:getPregapSectors).and_return 0
      cue.test_printTrackDataImage('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should write the ISRC for tracks where the info is found" do
      cdrdao.stub!(:getPregapSectors).and_return 0
      cdrdao.stub!(:getIsrcForTrack).with(1).and_return 'someISRCcode'
      cdrdao.stub!(:getIsrcForTrack).with(2).and_return ''
      cdrdao.stub!(:getIsrcForTrack).with(3).and_return 'someOtherISRCcode'
      @cuesheet.insert(4, '    ISRC "someISRCcode"')
      @cuesheet.insert(13, '    ISRC "someOtherISRCcode"')
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
      @cuesheet.insert(4, '    PREGAP 00:01:25')
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
  
  context "When printing the track info for prepend based track ripping" do
    before(:each) do
      cdrdao.stub!(:preEmph?).and_return false
      cdrdao.stub!(:getPregapSectors).and_return 0
      prefs.stub!(:preGaps).and_return 'prepend'
      prefs.stub!(:image).and_return false
      @cuesheet = ['FILE "Track_1.flac" WAVE',
                   '  TRACK 01 AUDIO', '    TITLE "Title track 1"',
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00',
                   'FILE "Track_2.flac" WAVE',
                   '  TRACK 02 AUDIO', '    TITLE "Title track 2"',
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00',
                   'FILE "Track_3.flac" WAVE',
                   '  TRACK 03 AUDIO', '    TITLE "Title track 3"',
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00']
    end
    
    it "should handle the default case for a disc correctly" do
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should set the pre-emphasis flag if the preference is marking in cuesheet" do
      prefs.stub!(:preEmphasis).and_return 'cue'
      cdrdao.stub!(:preEmph?).with(2).and_return true
      @cuesheet.insert(9, '    FLAGS PRE')
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should skip the pre-emphasis flag if the preference is decoding with sox" do
      prefs.stub!(:preEmphasis).and_return 'sox'
      cdrdao.stub!(:preEmph?).with(2).and_return true
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should prepend the gap to the track" do
      cdrdao.stub!(:getPregapSectors).with(2).and_return 40
      @cuesheet.insert(9, '    INDEX 00 00:00:00')
      @cuesheet[10] = '    INDEX 01 00:00:40'
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end
  end
  
  context "When printing the track info for append based track ripping" do
    before(:each) do
      cdrdao.stub!(:preEmph?).and_return false
      cdrdao.stub!(:getPregapSectors).and_return 0
      prefs.stub!(:preGaps).and_return 'append'
      prefs.stub!(:image).and_return false
      @cuesheet = ['FILE "Track_1.flac" WAVE',
                   '  TRACK 01 AUDIO', '    TITLE "Title track 1"',
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00',
                   'FILE "Track_2.flac" WAVE',
                   '  TRACK 02 AUDIO', '    TITLE "Title track 2"',
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00',
                   'FILE "Track_3.flac" WAVE',
                   '  TRACK 03 AUDIO', '    TITLE "Title track 3"',
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00']
    end
    
    it "should handle the default case for a disc correctly" do
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should set the pre-emphasis flag if the preference is marking in cuesheet" do
      prefs.stub!(:preEmphasis).and_return 'cue'
      cdrdao.stub!(:preEmph?).with(2).and_return true
      @cuesheet.insert(9, '    FLAGS PRE')
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should skip the pre-emphasis flag if the preference is decoding with sox" do
      prefs.stub!(:preEmphasis).and_return 'sox'
      cdrdao.stub!(:preEmph?).with(2).and_return true
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should append the gaps to previous track for last track" do
      cdrdao.stub!(:getPregapSectors).with(3).and_return 40
      @cuesheet.delete_at(10)
      @cuesheet.insert(13, '    INDEX 00 00:02:35')
      @cuesheet.insert(14, 'FILE "Track_3.flac" WAVE')
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end
    
    it "should append the gaps to track 1 for second track" do
      cdrdao.stub!(:getPregapSectors).with(2).and_return 40
      @cuesheet.delete_at(5)
      @cuesheet.insert(8, '    INDEX 00 00:02:35')
      @cuesheet.insert(9, 'FILE "Track_2.flac" WAVE')
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end    
  end
  
  context "When printing the info for 1st track with hidden sectors" do
    before(:each) do
      disc.startSectors[1] = 450 # 450 / 75 = 6 seconds
      cdrdao.stub!(:preEmph?).and_return false
      cdrdao.stub!(:getPregapSectors).and_return 0
      prefs.stub!(:preGaps).and_return 'prepend'
      prefs.stub!(:image).and_return false
      @cuesheet = ['FILE "Track_1.flac" WAVE',
                   '  TRACK 01 AUDIO', '    TITLE "Title track 1"',
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00',
                   'FILE "Track_2.flac" WAVE',
                   '  TRACK 02 AUDIO', '    TITLE "Title track 2"',
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00',
                   'FILE "Track_3.flac" WAVE',
                   '  TRACK 03 AUDIO', '    TITLE "Title track 3"',
                   '    PERFORMER "Iron Maiden"', '    INDEX 01 00:00:00']
    end

    it "should mark a pregap if the sectors are not ripped" do
      prefs.stub!(:ripHiddenAudio).and_return false
      @cuesheet.insert(4, '    PREGAP 00:06:00')
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end

    it "should prepend to track 1 if hidden sectors are < seconds than preference" do
      prefs.stub!(:ripHiddenAudio).and_return true
      prefs.stub!(:minLengthHiddenTrack).and_return 7
      @cuesheet.insert(4, '    INDEX 00 00:00:00')
      @cuesheet[5] = '    INDEX 01 00:06:00'
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end

    it "should use a pregap if hidden sectors are >= seconds than preference" do
      prefs.stub!(:ripHiddenAudio).and_return true
      prefs.stub!(:minLengthHiddenTrack).and_return 6
      @cuesheet.insert(4, '    PREGAP 00:06:00')
      cue.test_printTrackData('flac')
      cue.cuesheet.should == @cuesheet
    end
  end
end
