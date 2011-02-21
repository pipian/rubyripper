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

require 'spec_helper'

describe FreedbRecordParser do

  let(:parser) {FreedbRecordParser.new()}

  context "When the string is not an UTF-8 encoded string" do
    it "should detect if it has no valid encoding and abort" do
      nonUTF8 = "hello red \xE8".force_encoding("UTF-8")
      parser.parse(nonUTF8)

      parser.status.should == 'noValidEncoding'
      parser.metadata.should == nil
    end
    
    it "should detect if the encoding is not UTF-8 and abort" do
      latin1 = "some_crazy_text".encode('ISO-8859-1')
      parser.parse(latin1)

      parser.status.should == 'noUTF8Encoding'
      parser.metadata.should == nil
    end
  end

  context "When parsing a valid freedb metadata file" do
    it "should ignore the commented lines" do
      record = "DGENRE=Gothic\n#DISCID=98113b0e\nDYEAR=1993".encode('UTF-8')
      parser.parse(record)

      parser.status.should == 'ok'
      parser.metadata['genre'].should == 'Gothic'
      parser.metadata['discid'].should == nil
      parser.metadata['year'].should == '1993'
    end

    it "should parse all standard info" do
      record = "DISCID=98113b0e\nDTITLE=Type O Negative / Bloody \
Kisses\nDYEAR=1993\nDGENRE=Gothic\nTTITLE0=Machine Screw\n\
TTITLE1=Christian Woman".encode('UTF-8')
      parser.parse(record)

      parser.status.should == 'ok'
      parser.metadata['discid'].should == '98113b0e'
      parser.metadata['artist'].should == 'Type O Negative'
      parser.metadata['album'].should == 'Bloody Kisses'
      parser.metadata['genre'].should == 'Gothic'
      parser.metadata['tracklist'][1].should == 'Machine Screw'
      parser.metadata['tracklist'][2].should == 'Christian Woman'
    end

    it "should parse extra disc info" do
      record = "EXTD=What a wonderfull show!".encode('UTF-8')
      parser.parse(record)

      parser.status.should == 'ok'
      parser.metadata['extraDiscInfo'].should == 'What a wonderfull show!'
    end

    it "should recognize a trackname of two lines and add a space in between" do
      record = "TTITLE9=Part1\nTTITLE9=Part2".encode('UTF-8')
      parser.parse(record)

      parser.status.should == 'ok'
      parser.metadata['tracklist'][10].should == 'Part1 Part2'
    end

    it "should recognize the album if the title has two lines" do
      record = "DTITLE=Artist / Album\nDTITLE=with a longer name".encode('UTF-8')
      parser.parse(record)

      parser.status.should == 'ok'
      parser.metadata['artist'].should == 'Artist'
      parser.metadata['album'].should == 'Album with a longer name'
    end

    it "should recognize the artist if it spins two lines as well" do
      record = "DTITLE=Artist\nDTITLE=with a long name / Album".encode('UTF-8')
      parser.parse(record)

      parser.status.should == 'ok'
      parser.metadata['artist'].should == 'Artist with a long name'
      parser.metadata['album'].should == 'Album'
    end

    context "When a various artist disc is expected" do
      it "should recognize a various artist disc separated by a '/'" do
        record = "TTITLE2=MUNGO JERRY / In The Summertime\nTTITLE3=THE \
EASYBEATS / Friday on my Mind".encode('UTF-8')
        parser.parse(record)

        parser.status.should == 'ok'
        parser.metadata['varArtist'][3].should == 'MUNGO JERRY'
        parser.metadata['varArtist'][4].should == 'THE EASYBEATS'
        parser.metadata['tracklist'][3].should == 'In The Summertime'
        parser.metadata['tracklist'][4].should == 'Friday on my Mind'
      end

      it "should recognize a various artist disc separated by a '-'" do
        record = "TTITLE2=MUNGO JERRY - In The Summertime\nTTITLE3=THE \
EASYBEATS - Friday on my Mind".encode('UTF-8')
        parser.parse(record)

        parser.status.should == 'ok'
        parser.metadata['varArtist'][3].should == 'MUNGO JERRY'
        parser.metadata['varArtist'][4].should == 'THE EASYBEATS'
        parser.metadata['tracklist'][3].should == 'In The Summertime'
        parser.metadata['tracklist'][4].should == 'Friday on my Mind'
      end

      it "should recognize a various artist disc separated by a ':'" do
        record = "TTITLE2=MUNGO JERRY: In The Summertime\nTTITLE3=THE \
EASYBEATS : Friday on my Mind".encode('UTF-8')
        parser.parse(record)

        parser.status.should == 'ok'
        parser.metadata['varArtist'][3].should == 'MUNGO JERRY'
        parser.metadata['varArtist'][4].should == 'THE EASYBEATS'
        parser.metadata['tracklist'][3].should == 'In The Summertime'
        parser.metadata['tracklist'][4].should == 'Friday on my Mind'
      end

      it "should recognize a various artist disc separated by different splitters" do
        record = "TTITLE2=MUNGO JERRY : In The Summertime\nTTITLE3=THE \
EASYBEATS - Friday on my Mind\nTTITLE4=THE EASYBEATS / Friday on my Mind".encode('UTF-8')
        parser.parse(record)

        parser.status.should == 'ok'
        parser.metadata['varArtist'][3].should == 'MUNGO JERRY'
        parser.metadata['varArtist'][4].should == 'THE EASYBEATS'
        parser.metadata['varArtist'][5].should == 'THE EASYBEATS'
        parser.metadata['tracklist'][3].should == 'In The Summertime'
        parser.metadata['tracklist'][4].should == 'Friday on my Mind'
        parser.metadata['tracklist'][5].should == 'Friday on my Mind'
      end

      it "should allow to revert to the old tracknames before splitting" do
        record = "TTITLE2=MUNGO JERRY / In The Summertime\nTTITLE3=THE \
EASYBEATS / Friday on my Mind".encode('UTF-8')
        parser.parse(record)
        parser.undoVarArtist()
      
        parser.metadata['tracklist'][3].should == 'MUNGO JERRY / In The Summertime'
        parser.metadata['tracklist'][4].should == 'THE EASYBEATS / Friday on my Mind'
        parser.metadata['oldTracklist'].should == nil
      end

      it "should allow to redo the various artist splitting" do
        record = "TTITLE2=MUNGO JERRY / In The Summertime\nTTITLE3=THE \
EASYBEATS / Friday on my Mind".encode('UTF-8')
        parser.parse(record)
        parser.undoVarArtist()
        parser.redoVarArtist()

        parser.metadata['varArtist'][3].should == 'MUNGO JERRY'
        parser.metadata['varArtist'][4].should == 'THE EASYBEATS'
        parser.metadata['tracklist'][3].should == 'In The Summertime'
        parser.metadata['tracklist'][4].should == 'Friday on my Mind'
      end
    end
  end
end