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

require 'rubyripper/codecs/main'

# stub any method, also provide the double quotes
class TagFilterStub
  private 
  def method_missing(name, *args)
    args.empty? ? "\"#{name.to_s}\"" : "\"#{name.to_s} #{args[0]}\""
  end
end

describe Codecs::Main do
  
  let(:disc) {double('Disc').as_null_object}
  let(:scheme) {double('FileScheme').as_null_object}
  let(:tags) {TagFilterStub.new()}
  let(:prefs) {double('Preferences').as_null_object}
  let(:md) {double('Metadata').as_null_object}
  
  context "Given mp3 is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('mp3', disc, scheme, tags, prefs, md)
    end
    
    it "should return the command to replaygain a track" do
      scheme.should_receive(:getFile).with(1, 'mp3').and_return 'output.mp3'
      @codec.replaygain(1).should == 'mp3gain -c -r "output.mp3"'
    end
    
    it "should return the command to replaygain an album" do
      scheme.should_receive(:getDir).with('mp3').and_return '/home/mp3'
      @codec.replaygainAlbum().should == 'mp3gain -c -a "/home/mp3"/*.mp3'
    end
    
    # all conditional logic is only tested for mp3 since it's generic
    context "When calculating the command for encoding a track" do
      before(:each) do
        prefs.should_receive(:settingsMp3).and_return '-V 2'
        scheme.should_receive(:getTempFile).with(1).and_return 'input_1.wav'
        scheme.should_receive(:getFile).with(1, 'mp3').and_return '/home/mp3/1-test.mp3'
        disc.should_receive(:audiotracks).and_return 99
      end
      
      it "should be able to generate the basic command" do
        md.should_receive(:various?).and_return nil
        disc.should_receive(:freedbDiscid).and_return nil

        @codec.command(1).should == 'lame -V 2 --ta "trackArtist 1" --tl "album" '\
            '--tv TCON="genre" --ty "year" --tv TENC="Rubyripper test" --tt "trackname 1" '\
            '--tn 1/99 "input_1.wav" "/home/mp3/1-test.mp3"'
        @codec.setTagsAfterEncoding(1).should == ''
      end
      
      it "should add the various artist tag if relevant" do
        md.should_receive(:various?).and_return true
        disc.should_receive(:freedbDiscid).and_return nil
        
        @codec.command(1).should == 'lame -V 2 --ta "trackArtist 1" --tl "album" '\
            '--tv TCON="genre" --ty "year" --tv TPE2="artist" --tv TENC="Rubyripper test" '\
            '--tt "trackname 1" --tn 1/99 "input_1.wav" "/home/mp3/1-test.mp3"'
      end
      
      it "should add the discid if available" do
        md.should_receive(:various?).and_return nil
        disc.should_receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
        
        @codec.command(1).should == 'lame -V 2 --ta "trackArtist 1" --tl "album" '\
            '--tv TCON="genre" --ty "year" --tv TENC="Rubyripper test" --tc DISCID="ABCDEFGH" '\
            '--tt "trackname 1" --tn 1/99 "input_1.wav" "/home/mp3/1-test.mp3"'
      end
      
      it "should add the discnumber if available" do
        md.should_receive(:various?).and_return nil
        md.should_receive(:discNumber).twice.and_return "1"
        disc.should_receive(:freedbDiscid).and_return nil
        
        @codec.command(1).should == 'lame -V 2 --ta "trackArtist 1" --tl "album" '\
            '--tv TCON="genre" --ty "year" --tv TPOS=1 --tv TENC="Rubyripper test" --tt '\
            '"trackname 1" --tn 1/99 "input_1.wav" "/home/mp3/1-test.mp3"'
      end
    end
  end
  
  context "Given vorbis is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('vorbis', disc, scheme, tags, prefs, md)
    end
    
    it "should return the command to replaygain a track" do
      scheme.should_receive(:getFile).with(1, 'vorbis').and_return 'output.ogg'
      @codec.replaygain(1).should == 'vorbisgain "output.ogg"'
    end
    
    it "should return the command to replaygain an album" do
      scheme.should_receive(:getDir).with('vorbis').and_return '/home/vorbis'
      @codec.replaygainAlbum.should == 'vorbisgain -a "/home/vorbis"/*.ogg'
    end
    
    it "should calculate the command for encoding" do
      prefs.should_receive(:settingsVorbis).and_return '-q 6'
      scheme.should_receive(:getTempFile).with(1).and_return 'input_1.wav'
      scheme.should_receive(:getFile).with(1, 'vorbis').and_return '/home/vorbis/1-test.ogg'
      disc.should_receive(:audiotracks).and_return 99
      md.should_receive(:various?).and_return true
      md.should_receive(:discNumber).twice.and_return "1"
      disc.should_receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      
      @codec.command(1).should == 'oggenc -o "/home/vorbis/1-test.ogg" -q 6 -c '\
          'ARTIST="trackArtist 1" -c ALBUM="album" -c GENRE="genre" -c DATE="year" -c '\
          '"ALBUM ARTIST"="artist" -c DISCNUMBER=1 -c ENCODER="Rubyripper test" -c '\
          'DISCID="ABCDEFGH" -c TITLE="trackname 1" -c TRACKNUMBER=1 -c TRACKTOTAL=99 "input_1.wav"'
      @codec.setTagsAfterEncoding(1).should == ''
    end
  end
  
  context "Given flac is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('flac', disc, scheme, tags, prefs, md)
    end
    
    it "should return the command to replaygain a track" do
      scheme.should_receive(:getFile).with(1, 'flac').and_return 'output.flac'
      @codec.replaygain(1).should == 'metaflac --add-replay-gain "output.flac"'
    end
    
    it "should return the command to replaygain an album" do
      scheme.should_receive(:getDir).with('flac').and_return '/home/flac'
      @codec.replaygainAlbum.should == 'metaflac --add-replay-gain "/home/flac"/*.flac'
    end
    
    it "should calculate the command for encoding" do
      prefs.should_receive(:settingsFlac).and_return '-q 6'
      prefs.should_receive(:createCue).and_return false
      scheme.should_receive(:getTempFile).with(1).and_return 'input_1.wav'
      scheme.should_receive(:getFile).with(1, 'flac').and_return '/home/flac/1-test.flac'
      disc.should_receive(:audiotracks).and_return 99
      md.should_receive(:various?).and_return true
      md.should_receive(:discNumber).twice.and_return "1"
      disc.should_receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      
      @codec.command(1).should == 'flac -o "/home/flac/1-test.flac" -q 6 --tag '\
          'ARTIST="trackArtist 1" --tag ALBUM="album" --tag GENRE="genre" --tag DATE="year" '\
          '--tag "ALBUM ARTIST"="artist" --tag DISCNUMBER=1 --tag ENCODER="Rubyripper test" '\
          '--tag DISCID="ABCDEFGH" --tag TITLE="trackname 1" --tag TRACKNUMBER=1 --tag '\
          'TRACKTOTAL=99 "input_1.wav"'
      @codec.setTagsAfterEncoding(1).should == ''
    end
    
    it "should save the cuesheet file if available" do
      prefs.should_receive(:settingsFlac).and_return '-q 6'
      prefs.should_receive(:createCue).and_return true
      scheme.should_receive(:getCueFile).and_return '/home/flac/test.cue'
      scheme.should_receive(:getTempFile).with(1).and_return 'input_1.wav'
      scheme.should_receive(:getFile).with(1, 'flac').and_return '/home/flac/1-test.flac'
      disc.should_receive(:audiotracks).and_return 99
      md.should_receive(:various?).and_return true
      md.should_receive(:discNumber).twice.and_return "1"
      disc.should_receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      
      @codec.command(1).should == 'flac -o "/home/flac/1-test.flac" -q 6 --tag '\
          'ARTIST="trackArtist 1" --tag ALBUM="album" --tag GENRE="genre" --tag DATE="year" '\
          '--tag "ALBUM ARTIST"="artist" --tag DISCNUMBER=1 --tag ENCODER="Rubyripper test" '\
          '--tag DISCID="ABCDEFGH" --tag TITLE="trackname 1" --tag TRACKNUMBER=1 --tag '\
          'TRACKTOTAL=99 --cuesheet="/home/flac/test.cue" "input_1.wav"'
    end
  end
  
  context "Given wav is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('wav', disc, scheme, tags, prefs, md)
    end
    
    it "should return the command to replaygain a track" do
      scheme.should_receive(:getFile).with(1, 'wav').and_return 'output.wav'
      @codec.replaygain(1).should == 'wavegain "output.wav"'
    end
    
    it "should return the command to replaygain an album" do
      scheme.should_receive(:getDir).with('wav').and_return '/home/wav'
      @codec.replaygainAlbum.should == 'wavegain -a "/home/wav"/*.wav'
    end
    
    it "should calculate the command for encoding" do
      scheme.should_receive(:getTempFile).with(1).and_return 'input_1.wav'
      scheme.should_receive(:getFile).with(1, 'wav').and_return '/home/wav/1-test.wav'   
      @codec.command(1).should == 'cp "input_1.wav" "/home/wav/1-test.wav"'
      @codec.setTagsAfterEncoding(1).should == ''
    end
  end
  
  context "Given Nero aac is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('nero', disc, scheme, tags, prefs, md)
    end
    
    it "should return the command to replaygain a track" do
      scheme.should_receive(:getFile).with(1, 'nero').and_return 'output.aac'
      @codec.replaygain(1).should == 'aacgain -c -r "output.aac"'
    end
    
    it "should return the command to replaygain an album" do
      scheme.should_receive(:getDir).with('nero').and_return '/home/nero'
      @codec.replaygainAlbum().should == 'aacgain -c -a "/home/nero"/*.aac'
    end
       
    it "should calculate the command for encoding and tagging" do
      prefs.should_receive(:settingsNero).and_return '-q 1'
      scheme.should_receive(:getTempFile).with(1).and_return 'input_1.wav'
      scheme.should_receive(:getFile).with(1, 'nero').twice.and_return '/home/nero/1-test.aac'
      disc.should_receive(:audiotracks).and_return 99
      md.should_receive(:various?).and_return true
      md.should_receive(:discNumber).twice.and_return "1"
      disc.should_receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      
      @codec.command(1).should == 'neroAacEnc -q 1 -if "input_1.wav" -of "/home/nero/1-test.aac"'
      @codec.setTagsAfterEncoding(1).should == 'neroAacTag "/home/nero/1-test.aac" '\
          '-meta:artist="trackArtist 1" -meta:album="album" -meta:genre="genre" -meta:year="year" '\
          '-meta-user:"ALBUM ARTIST"="artist" -meta:disc=1 -meta-user:ENCODER="Rubyripper test" '\
          '-meta-user:DISCID="ABCDEFGH" -meta:title="trackname 1" -meta:track=1 -meta:totaltracks=99'
    end
  end
  
  context "Given wavpack is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('wavpack', disc, scheme, tags, prefs, md)
    end
    
    it "should return an empty string for the replaygain commands (not available)" do
      scheme.should_receive(:getFile).with(1, 'wavpack').and_return 'output.wv'
      @codec.replaygain(1).should == ''
      scheme.should_receive(:getDir).with('wavpack').and_return '/home/wavpack'
      @codec.replaygainAlbum.should == ''
    end
    
    it "should calculate the command for encoding" do
      prefs.should_receive(:settingsWavpack).and_return ''
      prefs.should_receive(:createCue).and_return true
      scheme.should_receive(:getCueFile).and_return '/home/wavpack/test.cue'
      scheme.should_receive(:getTempFile).with(1).and_return 'input_1.wav'
      scheme.should_receive(:getFile).with(1, 'wavpack').and_return '/home/wavpack/1-test.wv'
      disc.should_receive(:audiotracks).and_return 99
      md.should_receive(:various?).and_return true
      md.should_receive(:discNumber).twice.and_return "1"
      disc.should_receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      
      @codec.command(1).should == 'wavpack -w ARTIST="trackArtist 1" -w ALBUM="album" '\
          '-w GENRE="genre" -w DATE="year" -w "ALBUM ARTIST"="artist" -w DISCNUMBER=1 -w '\
          'ENCODER="Rubyripper test" -w DISCID="ABCDEFGH" -w TITLE="trackname 1" -w TRACKNUMBER=1 -w '\
          'TRACKTOTAL=99 -w CUESHEET="/home/wavpack/test.cue" "input_1.wav" -o "/home/wavpack/1-test.wv"'
      @codec.setTagsAfterEncoding(1).should == ''
    end
  end
end
