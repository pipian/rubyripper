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

describe "Given I have a disc inserted and want to rip tracks" do
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

  context "When I am in the main menu" do
    it "Should have an option to select tracks, by default all tracks are selected" do
      start()
      output.should be_visible(' 4) Select the tracks to rip (default = all)')
    end
  end

  context "When I go to the track selection menu" do
    it "should show an overview of all tracks to toggle" do
      input << 4
      start()
      output.should be_visible('** TRACK SELECTION **')
      output.should be_visible(' 1) Terminal Show                  [*]')
      output.should be_visible(' 2) Killers                        [*]')
      output.should be_visible(' 3) In The Name Of Tragedy         [*]')
      output.should be_visible(' 4) Suicide                        [*]')
      output.should be_visible(' 5) Life\'s A Bitch                 [*]')
      output.should be_visible(' 6) Down On Me                     [*]')
      output.should be_visible(' 7) In The Black                   [*]')
      output.should be_visible(' 8) Fight                          [*]')
      output.should be_visible(' 9) In The Year Of The Wolf        [*]')
      output.should be_visible('10) Keys To The Kingdom            [*]')
      output.should be_visible('11) Smiling Like A Killer          [*]')
      output.should be_visible('12) Whorehouse Blues               [*]')
      output.should be_visible('88) To toggle all tracks on/off')
      output.should be_visible('99) Back to main menu')
      output.should be_visible('Please type the number you wish to change [99] : ')
    end

    it "should allow to toggle all tracks off at once" do
      input << 4 ; input << 88
      start()
      output.should be_visible(' 1) Terminal Show                  [ ]')
      output.should be_visible(' 7) In The Black                   [ ]')
      output.should be_visible('12) Whorehouse Blues               [ ]')
    end

    it "should allow to toggle all tracks on at once" do
      input << 4 ; input << 88 ; input << 88
      start()
      output.count(' 1) Terminal Show                  [*]').should == 2
      output.count(' 7) In The Black                   [*]').should == 2
      output.count('12) Whorehouse Blues               [*]').should == 2
    end

    it "should remember the track selection when going back" do
      input << 4 ; input << 1 ; input.pressEnter ; input << 4
      start()
      output.count(' 1) Terminal Show                  [ ]').should == 2
    end

    it "should show a message if an input is not valid" do
      input << 4 ; input << 13
      start()
      output.should be_visible('Number 13 is not a valid choice, try again.')
    end
  end
end
