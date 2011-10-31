#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2011  Ian Jacobi (pipian@pipian.com)
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

require 'rubyripper/musicbrainz/musicbrainzReleaseParser'
require 'rubyripper/freedb/metadata'
require 'rexml/document'

describe MusicBrainzReleaseParser do

  def readRelease(doc)
    return REXML::XPath::first(REXML::Document.new(File.read(doc)), '//metadata/release', {''=>'http://musicbrainz.org/ns/mmd-2.0#'})
  end

  let(:prefs) {double('Preferences').as_null_object}
  let(:http) {double('MusicBrainzWebService').as_null_object}
  let(:parser) {MusicBrainzReleaseParser.new(nil, http, prefs)}

  context "Before parsing the disc" do
    it "should set some default values" do
      parser.md.artist.should == 'Unknown'
      parser.md.album.should == 'Unknown'
      parser.md.genre.should == 'Unknown'
      parser.md.year.should == '0'
      parser.md.extraDiscInfo.should == ''
      parser.md.discid.should == ''
      parser.md.trackname(12).should == 'Track 12'
      parser.md.getVarArtist(12).should == 'Unknown'
    end
  end

  context "When parsing a MusicBrainz release XML element" do
    before(:each) do
      prefs.stub(:useEarliestDate).and_return false
      http.stub(:get).and_return File.read('spec/musicbrainz/data/noTags.xml')
      http.stub(:path).and_return '/ws/2/'
    end

    it "should parse all standard info" do
      parser.parse(readRelease('spec/musicbrainz/data/standardRelease.xml'),
                   '4vi.H1hC7BRP18_a.7D4r4NOYL8-', 'e50b3c11')

      parser.status.should == 'ok'
      parser.md.discid.should == 'e50b3c11'
      parser.md.artist.should == 'The Beatles'
      parser.md.album.should == 'Abbey Road'
      parser.md.year.should == '2009'
      parser.md.trackname(1).should == 'Come Together'
      parser.md.trackname(2).should == 'Something'
    end

    it "should pick the correct disc of a multi-disc release" do
      parser.parse(readRelease('spec/musicbrainz/data/multiDiscRelease.xml'),
                   '0gLvTHxPtWugkT0Pf26t5Bjo0GQ-', 'b20b140d')

      parser.status.should == 'ok'
      parser.md.discid.should == 'b20b140d'
      parser.md.artist.should == 'The Beatles'
      parser.md.album.should == 'The Beatles'
      parser.md.year.should == '2009'
      parser.md.trackname(1).should == 'Birthday'
      parser.md.trackname(2).should == 'Yer Blues'
    end

    it "should use the earliest release date is useEarliestDate is set" do
      prefs.stub(:useEarliestDate).and_return true
      parser.parse(readRelease('spec/musicbrainz/data/standardRelease.xml'),
                   '4vi.H1hC7BRP18_a.7D4r4NOYL8-', 'e50b3c11')

      parser.status.should == 'ok'
      parser.md.year.should == '1969'
    end

    it "should never behave like a various artists disc if there is only one (non-Various Artists) album artist" do
      parser.parse(readRelease('spec/musicbrainz/data/oneAlbumArtist.xml'),
                   'cm9L.BbeuJ_zNOwr0C_e.K0.D0E-', '86099d0c')

      parser.status.should == 'ok'
      parser.md.artist.should == 'David Bowie'
      parser.md.various?.should == false
    end

    context "when guessing the genre" do
      it "should guess the most popular artist tag which is also an ID3 genre name" do
        http.should_receive(:get).with('/ws/2/artist/b10bbbfc-cf9e-42e0-be17-e2c3e1d2600d?inc=tags').and_return File.read('spec/musicbrainz/data/artistTags.xml')
        parser.parse(readRelease('spec/musicbrainz/data/multiDiscRelease.xml'),
                     '0gLvTHxPtWugkT0Pf26t5Bjo0GQ-', 'b20b140d')

        parser.md.genre.should == 'Rock'
      end

      it "should prefer release-group tags for genre over artist tags" do
        http.should_receive(:get).with('/ws/2/release-group/9162580e-5df4-32de-80cc-f45a8d8a9b1d?inc=tags').and_return File.read('spec/musicbrainz/data/releaseGroupTags.xml')
        parser.parse(readRelease('spec/musicbrainz/data/standardRelease.xml'),
                     '4vi.H1hC7BRP18_a.7D4r4NOYL8-', 'e50b3c11')

        parser.md.genre.should == 'Rock'
      end

      it "shouldn't set the genre if no good tag could be found" do
        # By default we return no tags
        parser.parse(readRelease('spec/musicbrainz/data/oneAlbumArtist.xml'),
                     'cm9L.BbeuJ_zNOwr0C_e.K0.D0E-', '86099d0c')

        parser.md.genre.should == nil
      end

      it "should map certain non-ID3-genre tags to ID3 genres" do
        http.should_receive(:get).with('/ws/2/artist/7dbac7e6-f351-42da-9dce-b0249ca2dd03?inc=tags').and_return File.read('spec/musicbrainz/data/mapTags.xml')
        parser.parse(readRelease('spec/musicbrainz/data/splitRelease.xml'),
                     'a2njxz76PKV7jgnudcTXDbV_OQs-', '79098308')

        # NOTE: Also shows capitalization
        parser.md.genre.should == 'Folk/Rock'
      end
    end

    context "when a various artists release is encountered" do
      it "should correctly know the artist for each track" do
        parser.parse(readRelease('spec/musicbrainz/data/variousArtists.xml'),
                     'c.J3z3pava1oPzXD0K2e9q48lJc-', 'c70ecd0f')

        parser.status.should == 'ok'
        parser.md.artist.should == 'Various Artists'
        parser.md.various?.should == true
        parser.md.getVarArtist(4).should == 'Bon Iver'
        parser.md.getVarArtist(5).should == 'Grizzly Bear'
        parser.md.trackname(4).should == 'Brackett, WI'
        parser.md.trackname(5).should == 'Deep Blue Sea'
      end

      it "should automatically join artist splits according to the joinphrase" do
        parser.parse(readRelease('spec/musicbrainz/data/variousArtists.xml'),
                     'c.J3z3pava1oPzXD0K2e9q48lJc-', 'c70ecd0f')

        parser.md.getVarArtist(3).should == 'Feist and Ben Gibbard'
      end

      it "should automatically join artist splits with ' / ' if there's no joinphrase" do
        parser.parse(readRelease('spec/musicbrainz/data/variousArtists.xml'),
                     'c.J3z3pava1oPzXD0K2e9q48lJc-', 'c70ecd0f')

        parser.md.getVarArtist(14).should == 'Grizzly Bear / Feist'
      end

      it "should rely on the track artists to pick the genre" do
        http.should_receive(:get).with('/ws/2/artist/1270af14-9c17-4400-8ebb-3f0ac40dcfb0?inc=tags').and_return File.read('spec/musicbrainz/data/artistTags.xml')
        parser.parse(readRelease('spec/musicbrainz/data/variousArtists.xml'),
                     'c.J3z3pava1oPzXD0K2e9q48lJc-', 'c70ecd0f')

        parser.md.genre.should == 'Rock'
      end
    end

    context "When a split artist release is encountered" do
      it "should automatically join album artist splits according to the joinphrase" do
        parser.parse(readRelease('spec/musicbrainz/data/splitReleaseOneArtist.xml'),
                     '7K8x8VRn_7QehSNMqHrzDhjZV_k-', 'b10df50d')

        parser.status.should == 'ok'
        parser.md.artist.should == 'Iron & Wine and Calexico'
      end

      it "should automatically join album artist splits with ' / ' if there's no joinphrase" do
        parser.parse(readRelease('spec/musicbrainz/data/splitRelease.xml'),
                     'a2njxz76PKV7jgnudcTXDbV_OQs-', '79098308')

        parser.status.should == 'ok'
        # NOTE: also relies on name-credit rather than artist/name
        parser.md.artist.should == 'Son, Ambulance / Bright Eyes'
      end

      it "should behave like a various artists disc" do
        parser.parse(readRelease('spec/musicbrainz/data/splitRelease.xml'),
                     'a2njxz76PKV7jgnudcTXDbV_OQs-', '79098308')

        parser.md.various?.should == true
        parser.md.getVarArtist(3).should == 'Son Ambulance'
        parser.md.getVarArtist(4).should == 'Bright Eyes'
        parser.md.trackname(3).should == 'The Invention of Beauty'
        parser.md.trackname(4).should == 'Oh, You Are the Roots That Sleep Beneath My Feet and Hold the Earth in Place'
      end

      it "should never behave like a various artists disc if all tracks have the same artist" do
        parser.parse(readRelease('spec/musicbrainz/data/splitReleaseOneArtist.xml'),
                     '7K8x8VRn_7QehSNMqHrzDhjZV_k-', 'b10df50d')

        parser.md.various?.should == false
      end

      it "should rely on the album artists to pick the genre" do
        http.should_receive(:get).with('/ws/2/artist/5e372a49-5672-4fb8-ba14-18c90780c4f9?inc=tags').and_return File.read('spec/musicbrainz/data/artistTags.xml')
        parser.parse(readRelease('spec/musicbrainz/data/splitReleaseOneArtist.xml'),
                     '7K8x8VRn_7QehSNMqHrzDhjZV_k-', 'b10df50d')

        parser.md.genre.should == 'Rock'
      end
    end
  end
end
