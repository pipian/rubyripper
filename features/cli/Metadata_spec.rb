# encoding: utf-8
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010  Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'features/feature_helper'

# For each test rubyripper is restarted and keyboard input is simulated
# Note that [ENTER] always lead to a higher menu until rubyripper exits
describe "Given the rubyripper CLI is started" do
  let(:output) {OutputMock.new}
  let(:input) {InputMock.new}
  let(:deps) {double('Dependency').as_null_object}

  # Use default preferences so our expectations are clear
  before(:all) do
    $TST_DEFAULT_PREFS = true
    $TST_DISC_PARANOIA = File.read(File.join(File.dirname(__FILE__), 
      '../data/discs/disc1/cdparanoia'))
    $TST_DISC_CDINFO = File.read(File.join(File.dirname(__FILE__), 
      '../data/discs/disc1/cdinfo'))
    $TST_DISC_FREEDB = File.read(File.join(File.dirname(__FILE__), 
      '../data/discs/disc1/freedb'))  
  end
  
  before(:each) do ; $TST_INPUT = input ; end

  def start
    app = CommandLineInterface.new(output, prefs=nil, deps, disc=nil, int=nil)
    app.start()
  end
  
  def setVariousDiscAndShowTracks
    input << 3 ; input << 1 ; input << 6 ; input.pressEnter() ; input << 2
  end
  
  context "When an audio disc is detected" do
    it "should show the disc info" do
      start()
      output.should be_visible('DISC INFO')
      output.should be_visible('Artist: Motörhead')
      output.should be_visible('Album: Inferno')
      output.should be_visible('Genre: Metal')
      output.should be_visible('Year: 2004')
      output.should be_visible('Extra disc info: YEAR: 2004')
      output.should be_visible('Marked as various disc? [ ]')
    end
    
    it "should show the track info" do
      start()
      output.should be_visible('TRACK INFO')
      output.should be_visible('1. Terminal Show')
      output.should be_visible('2. Killers')
      output.should be_visible('3. In The Name Of Tragedy')
      output.should be_visible('4. Suicide')
      output.should be_visible('5. Life\'s A Bitch')
      output.should be_visible('6. Down On Me')
      output.should be_visible('7. In The Black')
      output.should be_visible('8. Fight')
      output.should be_visible('9. In The Year Of The Wolf')
      output.should be_visible('10. Keys To The Kingdom')
      output.should be_visible('11. Smiling Like A Killer')
      output.should be_visible('12. Whorehouse Blues')
    end
    
    it "should offer a menu option to change the metadata" do
      start()
      output.should be_visible("* RUBYRIPPER MAIN MENU *")
      output.should be_visible(" 3) Change metadata")
    end
  end
  
  context "When I want to change the metadata" do
    it "should show me a menu for editing" do
      input << 3
      start()
      output.should be_visible('** EDIT METADATA **')
      output.should be_visible(' 1) Edit the disc info')
      output.should be_visible(' 2) Edit the track info')
      output.should be_visible('99) Return to main menu')
    end
    
    it "should show a menu to edit the disc info" do
      input << 3 ; input << 1
      start()
      output.should be_visible('*** EDIT DISC INFO ***')
      output.should be_visible(' 1) Artist: Motörhead')
      output.should be_visible(' 2) Album: Inferno')
      output.should be_visible(' 3) Genre: Metal')
      output.should be_visible(' 4) Year: 2004')
      output.should be_visible(' 5) Extra disc info: YEAR: 2004')
      output.should be_visible(' 6) Marked as various disc? [ ]')
      output.should be_visible('99) Back to metadata menu')
    end
    
    it "should allow to update the disc info" do
      input << 3 ; input << 1
      input << 1 ; input << 'Iron Maiden'
      input << 2 ; input << 'Number Of The Beast'
      input << 3 ; input << 'Heavy Metal'
      input << 4 ; input << '1983'
      input << 5 ; input << 'First album with Bruce Dickinson'
      input << 6
      start()
      output.should be_visible(' 1) Artist: Iron Maiden')
      output.should be_visible(' 2) Album: Number Of The Beast')
      output.should be_visible(' 3) Genre: Heavy Metal')
      output.should be_visible(' 4) Year: 1983')
      output.should be_visible(' 5) Extra disc info: First album with Bruce Dickinson')
      output.should be_visible(' 6) Marked as various disc? [*]')
    end
    
    it "should show a menu to edit the track info" do
      input << 3 ; input << 2
      start()
      output.should be_visible(' 1) Terminal Show')
      output.should be_visible(' 2) Killers')
      output.should be_visible(' 3) In The Name Of Tragedy')
      output.should be_visible(' 4) Suicide')
      output.should be_visible(' 5) Life\'s A Bitch')
      output.should be_visible(' 6) Down On Me')
      output.should be_visible(' 7) In The Black')
      output.should be_visible(' 8) Fight')
      output.should be_visible(' 9) In The Year Of The Wolf')
      output.should be_visible('10) Keys To The Kingdom')
      output.should be_visible('11) Smiling Like A Killer')
      output.should be_visible('12) Whorehouse Blues')
    end
    
    it "should allow to update the track info" do
      input << 3 ; input << 2
      (1..12).each{|track| input << track ; input << "Track #{track}"}
      start()
      (1..12).each{|track| output.should be_visible("%2d) Track #{track}" % track)}
    end
    
    context "When the disc is marked as various" do
      it "should mention a default artistname for each track" do
        setVariousDiscAndShowTracks()
        start()
        output.should be_visible(' 1) Unknown - Terminal Show')
        output.should be_visible(' 2) Unknown - Killers')
        output.should be_visible(' 3) Unknown - In The Name Of Tragedy')
        output.should be_visible(' 4) Unknown - Suicide')
        output.should be_visible(' 5) Unknown - Life\'s A Bitch')
        output.should be_visible(' 6) Unknown - Down On Me')
        output.should be_visible(' 7) Unknown - In The Black')
        output.should be_visible(' 8) Unknown - Fight')
        output.should be_visible(' 9) Unknown - In The Year Of The Wolf')
        output.should be_visible('10) Unknown - Keys To The Kingdom')
        output.should be_visible('11) Unknown - Smiling Like A Killer')
        output.should be_visible('12) Unknown - Whorehouse Blues')
      end
    
    	it "should allow to update the artist and trackname for each track" do
    		setVariousDiscAndShowTracks()
    		(1..12).each{|track| input << track ; input << "Artist #{track}" ; input << "Track #{track}"}		
    		start()
    		(1..12).each{|track| output.should be_visible("%2d) Artist #{track} - Track #{track}" % track)}
    	end
  	end 
  end
end
