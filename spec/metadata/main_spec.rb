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

require 'rubyripper/metadata/main'

describe Metadata::Main do
  
  let(:disc) {double('Disc').as_null_object}
  let(:prefs) {double('Preferences').as_null_object}
  let(:musicbrainz) {double('MusicBrainz').as_null_object}
  let(:freedb) {double('Freedb').as_null_object}
  let(:data) {double('Metadata::Data').as_null_object}
  let(:main) {Metadata::Main.new(disc,prefs,musicbrainz,freedb,data)}

  context "When the metadata for a disc is requested" do
    it "should use Musicbrainz if that is the preference" do
      prefs.stub!(:metadataProvider).and_return "musicbrainz"
      musicbrainz.should_receive(:get)
      musicbrainz.should_receive(:status).and_return 'ok'
      main.get.should == musicbrainz
    end
  
    it "should use Freedb if that is the preference" do
      prefs.stub!(:metadataProvider).and_return "freedb"
      freedb.should_receive(:get)
      freedb.should_receive(:status).and_return 'ok'
      main.get.should == freedb
    end
    
    it "should skip both providers if that is the preference" do
      prefs.stub!(:metadataProvider).and_return "none"
      main.get.should == data
    end
    
    context "Given the preference is set to musicbrainz" do
      before(:each) do
        prefs.stub!(:metadataProvider).and_return "musicbrainz"
      end
      
      it "should first fall back to Freedb if Musicbrainz fails" do
        musicbrainz.should_receive(:get)
        musicbrainz.should_receive(:status).and_return 'mayday'
        freedb.should_receive(:get)
        freedb.should_receive(:status).and_return 'ok'
        main.get.should == freedb
      end
      
      it "should fall back to none if Freedb fails as well" do
        musicbrainz.should_receive(:get)
        musicbrainz.should_receive(:status).and_return 'mayday'
        freedb.should_receive(:get)
        freedb.should_receive(:status).and_return 'mayday'
        main.get.should == data
      end
    end
    
    context "Given the preference is set to freedb" do
      before(:each) do
        prefs.stub!(:metadataProvider).and_return "freedb"
      end
      
      it "should first fall back to Musicbrainz if Freedb fails" do
        freedb.should_receive(:get)
        freedb.should_receive(:status).and_return 'mayday'
        musicbrainz.should_receive(:get)
        musicbrainz.should_receive(:status).and_return 'ok'
        main.get.should == musicbrainz
      end
      
      it "should fall back to none if Musicbrainz fails as well" do
        freedb.should_receive(:get)
        freedb.should_receive(:status).and_return 'mayday'
        musicbrainz.should_receive(:get)
        musicbrainz.should_receive(:status).and_return 'mayday'
        main.get.should == data
      end
    end
  end
end