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
describe "Given the rubyripper CLI is started and shows the main menu" do
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
  
  context "When I want to edit the metadata" do
    it "should show the disc info" do
      input.pressEnter()
      start()
      output.should be_visible('DISC INFO')
      output.should be_visible('Artist: Motörhead')
      output.should be_visible('Album: Inferno')
      output.should be_visible('Genre: Metal')
      output.should be_visible('Year: 2004')
      output.should be_visible('Extra disc info: YEAR: 2004')
      output.should be_visible('Marked as various disc? [ ]')
    end
    
    it "should offer a menu option to change the metadata" do
      input.pressEnter()
      start()
      output.should be_visible("* RUBYRIPPER MAIN MENU *")
      output.should be_visible(" 3) Change metadata")
    end
  end
end
