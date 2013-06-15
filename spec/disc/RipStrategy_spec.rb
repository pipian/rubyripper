require 'rubyripper/disc/ripStrategy'
require 'rubyripper/datamodel/disc'

describe RipStrategy do

  let(:prefs) {double('Preferences').as_null_object}

  context 'When no special attributes are there' do
    it 'should be able to create a new instance' do
      disc = Datamodel::Disc.new()
      strategy = RipStrategy.new(disc, prefs)
      strategy.class.should == RipStrategy
    end

    it 'should be able to show the cdparanoia parameters for a normal 1-track disc' do
      disc = Datamodel::Disc.new()
      disc.addTrack(number=1, startsector=0, lengthsector=1000)
      strategy = RipStrategy.new(disc, prefs)
      strategy.getTrack(1).startSector.should == 0
      strategy.getTrack(1).lengthSector.should == 1000
    end
  end

  context 'When hidden track info is available' do
    it 'should be able to detect a hidden track when bigger than minimum length preference' do
      data = Datamodel::Disc.new()
      data.addTrack(number=1, startsector=750, lengthsector=1000)
      prefs.stub!('ripHiddenAudio').and_return true
      prefs.stub!('minLengthHiddenTrack').and_return(0)
      strategy = RipStrategy.new(data, prefs)
      strategy.isHiddenTrackAvailable.should == true
      track = strategy.getHiddenTrack()
      track.startSector.should == 0
      track.lengthSector.should == 750
    end

    # 10 seconds * 75 = 750 frames
    it 'should be able to detect a hidden track when equal to minimum length preference' do
      data = Datamodel::Disc.new()
      data.addTrack(number=1, startsector=750, lengthsector=1000)
      prefs.stub!('ripHiddenAudio').and_return true
      prefs.stub!('minLengthHiddenTrack').and_return(10)
      strategy = RipStrategy.new(data, prefs)
      strategy.isHiddenTrackAvailable.should == true
      track = strategy.getHiddenTrack()
      track.startSector.should == 0
      track.lengthSector.should == 750
    end

    it 'should not detect a hidden track when smaller than minimum length preference' do
      data = Datamodel::Disc.new()
      data.addTrack(number=1, startsector=750, lengthsector=1000)
      prefs.stub!('ripHiddenAudio').and_return true
      prefs.stub!('minLengthHiddenTrack').and_return(11)
      strategy = RipStrategy.new(data, prefs)
      strategy.isHiddenTrackAvailable.should == false
      expect {strategy.getHiddenTrack}.to raise_error(RuntimeError)
    end

    it 'should ignore hidden track if ripHiddenAudio is disabled in preferences' do
      data = Datamodel::Disc.new()
      data.addTrack(number=1, startsector=750, lengthsector=1000)
      prefs.stub!('ripHiddenAudio').and_return false
      prefs.stub!('minLengthHiddenTrack').and_return(0)
      strategy = RipStrategy.new(data, prefs)
      strategy.isHiddenTrackAvailable.should == false
      expect {strategy.getHiddenTrack}.to raise_error(RuntimeError)
    end
  end
end