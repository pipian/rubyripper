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

require 'rubyripper/disc/scanDiscCdrdao'

describe ScanDiscCdrdao do

  let(:prefs) {double('Preferences').as_null_object}
  let(:exec) {double('Execute').as_null_object}
  let(:file) {double('FileAndDir').as_null_object}
  let(:log) {double('Log').as_null_object}
  let(:cdrdao) {ScanDiscCdrdao.new(exec, prefs, file)}
  
  before(:each){prefs.stub!(:cdrom).and_return('/dev/cdrom')}

  context "In case cdrdao exits with an error" do
    it "should detect cdrdao is not installed" do
      exec.stub!(:launch).and_return(nil)
      log.should_receive(:<<).with('Error: cdrdao is needed, but not detected on your system!')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
    end
    
    it "should detect if there is no disc in the drive" do
      exec.stub!(:launch).and_return('ERROR: Unit not ready, giving up.')
      log.should_receive(:<<).with('Error: There is no audio disc ready in drive /dev/cdrom.')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
    end
    
    it "should detect if there is a parameter problem" do
      exec.stub!(:launch).and_return('Usage: cdrdao')
      log.should_receive(:<<).with('Error: cdrdao does not recognize the parameters used.')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
    end
    
    it "should detect if the drive is not recognized" do
      exec.stub!(:launch).and_return('ERROR: Cannot setup device')
      log.should_receive(:<<).with('Error: The device /dev/cdrom doesn\'t exist on your system!')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
    end
    
    it "should not give a warning with correct results" do
      exec.stub!(:launch).and_return('ok')
      log.should_receive(:<<).with("No pregaps, silences, pre-emphasis or datatracks detected\n\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.error.nil? == true
    end
  end
  
  context "When parsing the file" do
    before(:each){exec.stub!(:launch).and_return('ok')}

    # notice there are 75 sectors in a second
    it "should detect if the disc starts with a silence" do
      file.should_receive(:read).and_return('SILENCE 00:01:20')
      log.should_receive(:<<).with("Silence detected for disc : 95 sectors\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.getSilenceSectors.should == 95
    end
    
    it "should detect if a track has a pregap" do
      file.should_receive(:read).and_return(%Q{// Track 3\n// Track 4\nSTART 00:00:35\n// Track 5})
      log.should_receive(:<<).with("Pregap detected for track 4 : 35 sectors\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.getPregapSectors(track=3).should == 0
      cdrdao.getPregapSectors(track=4).should == 35
      cdrdao.getPregapSectors(track=5).should == 0
    end
    
    it "should detect if a track has pre-emphasis" do
      file.should_receive(:read).and_return(%Q{// Track 3\n// Track 4\nPRE_EMPHASIS\n// Track 5})
      log.should_receive(:<<).with("Pre_emphasis detected for track 4\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.preEmph?(3).should == false
      cdrdao.preEmph?(4).should == true
      cdrdao.preEmph?(5).should == false
    end
    
    it "should detect data tracks" do
      file.should_receive(:read).and_return(%Q{// Track 3\n// Track 4\nTRACK DATA\n// Track 5\nTRACK DATA})
      log.should_receive(:<<).with("Track 4 is marked as a DATA track\n")
      log.should_receive(:<<).with("Track 5 is marked as a DATA track\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.dataTracks.should == [4,5]
    end
    
    it "should detect the type of the disc" do
      file.should_receive(:read).and_return('CD_DA')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.discType.should == 'CD_DA'
    end
    
    it "should detect the highest track number" do
      file.should_receive(:read).and_return(%Q{// Track 3\n// Track 4\nTRACK DATA\n// Track 5\nTRACK DATA})
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.tracks.should == 5
    end
  end
  
  context "When there is cd-text on the disc" do
    before(:each){exec.stub!(:launch).and_return('ok')}
    
    it "should detect the artist and album" do
      file.should_receive(:read).and_return(%Q[CD_TEXT {\n  LANGUAGE 0 {\n    TITLE "SYSTEM OF A DOWN   STEAL THIS ALBUM!"])
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.artist.should == "SYSTEM OF A DOWN"
      cdrdao.album.should == "STEAL THIS ALBUM!"
    end
    
    it "should detect the tracknames" do
      file.should_receive(:read).and_return(%Q[// Track 3\nCD_TEXT {\n  LANGUAGE 0 {\n    TITLE "BUBBLES"\n    PERFORMER ""\n  }\n}])
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.getTrackname(track=2).should == ""
      cdrdao.getTrackname(track=3).should == "BUBBLES"
      cdrdao.getTrackname(track=4).should == ""
    end
    
    it "should detect the various artists" do
      file.should_receive(:read).and_return(%Q[// Track 3\nCD_TEXT {\n  LANGUAGE 0 {\n    TITLE "BUBBLES"\n    PERFORMER "ABCDE"\n  }\n}])
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.getVarArtist(track=2).should == ""
      cdrdao.getVarArtist(track=3).should == "ABCDE"
      cdrdao.getVarArtist(track=4).should == ""
    end    
  end
end

# 

