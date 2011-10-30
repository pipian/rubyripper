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
  let(:disc) {ScanDiscCdrdao.new(exec, prefs)}

  context "Before scanning any disc" do
    it "shouldn't set default values" do
      disc.status.should == nil
      disc.log.should == nil
    end

    it "should raise an error when a function other than scan() is called" do
      lambda{disc.getSilenceSectors}.should raise_error(RuntimeError, /getSilenceSectors/)
      lambda{disc.getPregapSectors(1)}.should raise_error(RuntimeError, /getPregapSectors/)
      lambda{disc.preEmph?(1)}.should raise_exception(RuntimeError, /preEmph/)
    end
  end

  def setQueryReply(response, status='ok')
    prefs.should_receive(:cdrom).and_return('/dev/cdrom')
    exec.should_receive(:launch).with(%Q{cdrdao read-toc --device /dev/cdrom \"/tmp/cdrom.toc\"}, "/tmp/cdrom.toc")
    exec.should_receive(:getTempFile).with('cdrom.toc').and_return('/tmp/cdrom.toc')
    exec.should_receive(:status).and_return(status)
    exec.should_receive(:readFile).and_return(response) unless response.nil?
    disc.scan()
  end

  context "When the outputfile is not valid" do
     it "should detect if cdrdao is not installed" do
      setQueryReply(response=nil, status=nil)
      disc.status.should == 'notInstalled'
    end

    it "should detect if the drive is not valid" do
      setQueryReply(response='ERROR: Cannot setup device /dev/cdrom.')
      disc.status.should == 'unknownDrive'
    end

    it "should detect a problem with parameters" do
      setQueryReply(response='Usage: cdrdao <command> [options] [toc-file]')
      disc.status.should == 'wrongParameters'
    end

    it "should detect if there is no disc inserted" do
      setQueryReply(response="ERROR: Unit not ready, giving up.\nERROR: Cannot setup device /dev/cdrom.")
      disc.status.should == 'noDiscInDrive'
    end
  end

  context "When the outputfile is valid" do

    it "should detect if the disc starts with a silence" do
      setQueryReply(response='SILENCE 00:01:20')
      disc.getSilenceSectors.should == 95
      disc.status.should == 'ok'
    end

    it "should detect if a track has a pregap" do
      setQueryReply(response= %Q{// Track 3\n// Track 4\nSTART 00:00:35\n// Track 5})
      disc.getPregapSectors(track=2).should == 0
      disc.getPregapSectors(track=3).should == 0
      disc.getPregapSectors(track=4).should == 35
      disc.getPregapSectors(track=5).should == 0
      disc.getPregapSectors(track=6).should == 0
      disc.status.should == 'ok'
    end

    it "should detect if a track has pre-emphasis" do
      setQueryReply(response= %Q{// Track 3\n// Track 4\nPRE_EMPHASIS\n// Track 5})
      disc.preEmph?(2).should == false
      disc.preEmph?(3).should == false
      disc.preEmph?(4).should == true
      disc.preEmph?(5).should == false
      disc.preEmph?(6).should == false
      disc.status.should == 'ok'
    end

    it "should detect which tracks are a data track" do
      setQueryReply(response= %Q{// Track 3\n// Track 4\nTRACK DATA\n// Track 5\nTRACK DATA})
      disc.dataTracks.should == [4, 5]
      disc.status.should == 'ok'
    end

    it "should detect the type of the disc" do
      setQueryReply(response='CD_DA')
      disc.discType.should == 'CD_DA'
    end

    it "should detect the highest track number" do
      setQueryReply(response= %Q{// Track 3\n// Track 4\nTRACK DATA\n// Track 5\nTRACK DATA})
      disc.tracks.should == 5
    end
  end

  context "When there is cd-text on the disc" do
    it "should detect the artist and album" do
      response = %Q[CD_TEXT {\n  LANGUAGE 0 {\n    TITLE "SYSTEM OF A DOWN   STEAL THIS ALBUM!"]
      setQueryReply(response)
      disc.artist.should == "SYSTEM OF A DOWN"
      disc.album.should == "STEAL THIS ALBUM!"
    end

    it "should detect the tracknames" do
      response = %Q[// Track 3\nCD_TEXT {\n  LANGUAGE 0 {\n    TITLE "BUBBLES"\n    PERFORMER ""\n  }\n}]
      setQueryReply(response)
      disc.getTrackname(track=2).should == ""
      disc.getTrackname(track=3).should == "BUBBLES"
      disc.getTrackname(track=4).should == ""
    end

    it "should detect the various artists" do
      response = %Q[// Track 3\nCD_TEXT {\n  LANGUAGE 0 {\n    TITLE "BUBBLES"\n    PERFORMER "ABCDE"\n  }\n}]
      setQueryReply(response)
      disc.getVarArtist(track=2).should == ""
      disc.getVarArtist(track=3).should == "ABCDE"
      disc.getVarArtist(track=4).should == ""
    end
  end
end