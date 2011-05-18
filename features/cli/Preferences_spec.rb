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

# Note that [ENTER] always lead to a higher menu until rubyripper exits
describe "Given the rubyripper CLI is started and shows the main menu" do
  let(:output) {OutputMock.new}
  let(:input) {InputMock.new}
  let(:deps) {double('Dependency').as_null_object}
  let(:disc) {double('Disc').as_null_object}

  # launch a new cli passing a non-existant file so it uses defaults
  def start
    app = CommandLineInterface.new(output, prefs=nil, deps, disc, int=nil)
    app.start()
  end

  context "When I want to see the current rubyripper preferences" do
    it "should offer a menu option to change preferences" do
      input.pressEnter()
      start()
      output.should be_visible("* RUBYRIPPER MAIN MENU *")
      output.should be_visible(" 1) Change preferences")
    end

    it "should show the right menu when I choose 1) Change Preferences" do
      input << 1; 2.times{input.pressEnter}
      start()
      output.should be_visible("** RUBYRIPPER PREFERENCES **")
      output.should be_visible(" 1) Secure ripping")
      output.should be_visible(" 2) Toc analysis")
      output.should be_visible(" 3) Codecs")
      output.should be_visible(" 4) Freedb")
      output.should be_visible(" 5) Other")
      output.should be_visible("99) Don't change any setting")
    end

    it "should show the right submenu when I choose 1) Secure Ripping" do
      2.times{input << 1} ; 3.times{input.pressEnter()}
      start()
      output.should be_visible("*** SECURE RIPPING PREFERENCES ***")
      output.should be_visible(" 1) Ripping drive:", false)
      output.should be_visible(" 2) Drive offset:", false)
      output.should be_visible("   **Find your offset at http://www.accuraterip.com/driveoffsets.htm.")
      output.should be_visible("   **Your drive model is shown in the logfile.")
      output.should be_visible(" 3) Passing extra cdparanoia parameters:", false)
      output.should be_visible(" 4) Match all chunks:", false)
      output.should be_visible(" 5) Match erroneous chunks:", false)
      output.should be_visible(" 6) Maximum trials:", false)
      output.should be_visible(" 7) Eject disc after ripping [", false)
      output.should be_visible(" 8) Only keep log when errors [", false)
      output.should be_visible("99) Back to settings main menu")
    end

    it "should show the right submenu when I choose 2) Toc analysis" do
      input << 1 ; input << 2 ; 3.times{input.pressEnter()}
      start()
      output.should be_visible("*** TOC ANALYSIS PREFERENCES ***")
      output.should be_visible(" 1) Create a cuesheet [",false)
      output.should be_visible(" 2) Rip to single file [", false)
      output.should be_visible(" 3) Rip hidden audio sectors [", false)
      output.should be_visible(" 4) Minimum seconds hidden track:", false)
      output.should be_visible(" 5) Append or prepend audio:", false)
      output.should be_visible(" 6) Way to handle pre-emphasis:",false)
      output.should be_visible("99) Back to settings main menu", false)
    end

    it "should show the right submenu when I choose 3) Codecs" do
      input << 1 ; input << 3 ; 3.times{input.pressEnter()}
      start()
      output.should be_visible("*** CODEC PREFERENCES ***", false)
      output.should be_visible(" 1) Flac [", false)
      output.should be_visible(" 2) Flac options passed:", false)
      output.should be_visible(" 3) Vorbis [", false)
      output.should be_visible(" 4) Oggenc options passed:", false)
      output.should be_visible(" 5) Mp3 [", false)
      output.should be_visible(" 6) Lame options passed:", false)
      output.should be_visible(" 7) Wav [", false)
      output.should be_visible(" 8) Other codec [", false)
      output.should be_visible(" 9) Commandline passed:", false)
      output.should be_visible("10) Playlist support [", false)
      output.should be_visible("11) Maximum extra encoding threads:", false)
      output.should be_visible("12) Replace spaces with underscores [", false)
      output.should be_visible("13) Downsize all capital letters in filenames [", false)
      output.should be_visible("14) Normalize program:", false)
      output.should be_visible("15) Normalize modus:", false)
      output.should be_visible("99) Back to settings main menu")
    end

    it "should show the right submenu when I choose 4) Freedb" do
      input << 1 ; input << 4 ; 3.times{input.pressEnter()}
      start()
      output.should be_visible("*** FREEDB PREFERENCES ***")
      output.should be_visible(" 1) Fetch cd info with freedb [", false)
      output.should be_visible(" 2) Always use first hit [", false)
      output.should be_visible(" 3) Freedb server:", false)
      output.should be_visible(" 4) Freedb username:", false)
      output.should be_visible(" 5) Freedb hostname:", false)
      output.should be_visible("99) Back to settings main menu")
    end

    it "should show the right submenu when I choose 5) Other" do
      input << 1 ; input << 5 ; 3.times{input.pressEnter()}
      start()
      output.should be_visible("*** OTHER PREFERENCES ***")
      output.should be_visible(" 1) Base directory:", false)
      output.should be_visible(" 2) Standard filescheme:", false)
      output.should be_visible(" 3) Various artist filescheme:", false)
      output.should be_visible(" 4) Single file rip filescheme:", false)
      output.should be_visible(" 5) Log file viewer:", false)
      output.should be_visible(" 6) File manager:", false)
      output.should be_visible(" 7) Verbose mode [", false)
      output.should be_visible(" 8) Debug mode [", false)
      output.should be_visible("99) Back to settings main menu")
    end
  end

  context "When I want to update the ripper preferences"
  context "When I want to update the TOC analysis preferences"
  context "When I want to update the codecs preferences"
  context "When I want to update the freedb preferences"
  context "When I want to update the other preferences"
end