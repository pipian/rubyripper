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
  let(:disc) {double('Disc').as_null_object}

  # Use default preferences so our expectations are clear
  before(:all) do ; $TST_DEFAULT_PREFS = true ; end
  before(:each) do ; $TST_INPUT = input ; end

  def start
    app = CommandLineInterface.new(output, prefs=nil, deps, disc, int=nil)
    app.start()
  end

  context "When I want to see the current rubyripper preferences" do
    it "should offer a menu option to change preferences" do
      start()
      output.should be_visible("* RUBYRIPPER MAIN MENU *")
      output.should be_visible(" 1) Change preferences")
    end

    it "should show the right menu when I choose 1) Change Preferences" do
      input << 1
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
      2.times{input << 1}
      start()
      output.should be_visible("*** SECURE RIPPING PREFERENCES ***")
      output.should be_visible(" 1) Ripping drive: /dev/cdrom")
      output.should be_visible(" 2) Drive offset: 0")
      output.should be_visible("   **Find your offset at http://www.accuraterip.com/driveoffsets.htm.")
      output.should be_visible("   **Your drive model is shown in the logfile.")
      output.should be_visible(" 3) Passing extra cdparanoia parameters: -Z")
      output.should be_visible(" 4) Match all chunks: 2")
      output.should be_visible(" 5) Match erroneous chunks: 3")
      output.should be_visible(" 6) Maximum trials: 5")
      output.should be_visible(" 7) Eject disc after ripping [*]")
      output.should be_visible(" 8) Only keep log when errors [ ]")
      output.should be_visible("99) Back to settings main menu")
    end

    it "should show the right submenu when I choose 2) Toc analysis" do
      input << 1 ; input << 2
      start()
      output.should be_visible("*** TOC ANALYSIS PREFERENCES ***")
      output.should be_visible(" 1) Create a cuesheet [*]")
      output.should be_visible(" 2) Rip to single file [ ]")
      output.should be_visible(" 3) Rip hidden audio sectors [*]")
      output.should be_visible(" 4) Minimum seconds hidden track: 2")
      output.should be_visible(" 5) Append or prepend audio: prepend")
      output.should be_visible(" 6) Way to handle pre-emphasis: cue")
      output.should be_visible("99) Back to settings main menu")
    end

    it "should show the right submenu when I choose 3) Codecs" do
      input << 1 ; input << 3
      start()
      output.should be_visible("*** CODEC PREFERENCES ***")
      output.should be_visible(" 1) Flac [ ]")
      output.should be_visible(" 2) Flac options passed: --best -V")
      output.should be_visible(" 3) Vorbis [*]")
      output.should be_visible(" 4) Oggenc options passed: -q 4")
      output.should be_visible(" 5) Mp3 [ ]")
      output.should be_visible(" 6) Lame options passed: -V 3 --id3v2-only")
      output.should be_visible(" 7) Wav [ ]")
      output.should be_visible(" 8) Other codec [ ]")
      output.should be_visible(" 9) Commandline passed: ")
      output.should be_visible("10) Playlist support [*]")
      output.should be_visible("11) Maximum extra encoding threads: 2")
      output.should be_visible("12) Replace spaces with underscores [ ]")
      output.should be_visible("13) Downsize all capital letters in filenames [ ]")
      output.should be_visible("14) Normalize program: none")
      output.should be_visible("15) Normalize modus: album")
      output.should be_visible("99) Back to settings main menu")
    end

    it "should show the right submenu when I choose 4) Freedb" do
      input << 1 ; input << 4
      start()
      output.should be_visible("*** FREEDB PREFERENCES ***")
      output.should be_visible(" 1) Fetch cd info with freedb [*]")
      output.should be_visible(" 2) Always use first hit [*]")
      output.should be_visible(" 3) Freedb server: http://freedb.freedb.org/~cddb/cddb.cgi")
      output.should be_visible(" 4) Freedb username: anonymous")
      output.should be_visible(" 5) Freedb hostname: my_secret.com")
      output.should be_visible("99) Back to settings main menu")
    end

    it "should show the right submenu when I choose 5) Other" do
      input << 1 ; input << 5
      start()
      output.should be_visible("*** OTHER PREFERENCES ***")
      output.should be_visible(" 1) Base directory: /home/test")
      output.should be_visible(" 2) Standard filescheme: %f/%a (%y) %b/%n - %t")
      output.should be_visible(" 3) Various artist filescheme: %f/%va (%y) %b/%n - %a - %t")
      output.should be_visible(" 4) Single file rip filescheme: %f/%a (%y) %b/%a - %b (%y)")
      output.should be_visible(" 5) Log file viewer: mousepad")
      output.should be_visible(" 6) File manager: thunar")
      output.should be_visible(" 7) Verbose mode [ ]")
      output.should be_visible(" 8) Debug mode [ ]")
      output.should be_visible("99) Back to settings main menu")
    end

    context "When updating the preferences"
      it "should show the updated ripping preferences" do
        3.times{input << 1} ; input << '/dev/dvdrom' # ripping drive
        input << 2 ; input << 10 # offset
        input << 3 ; input << '-abcdef' # offset
        input << 4 ; input << 3 # all chunks
        input << 5 ; input << 4 # err chunks
        input << 6 ; input << 7 # max trials
        input << 7 # toggle eject
        input << 8 # only log when errors
        start()
        output.should be_visible(" 1) Ripping drive: /dev/dvdrom")
        output.should be_visible(" 2) Drive offset: 10")
        output.should be_visible(" 3) Passing extra cdparanoia parameters: -abcdef")
        output.should be_visible(" 4) Match all chunks: 3")
        output.should be_visible(" 5) Match erroneous chunks: 4")
        output.should be_visible(" 6) Maximum trials: 7")
        output.should be_visible(" 7) Eject disc after ripping [ ]")
        output.should be_visible(" 8) Only keep log when errors [*]")
      end

      it "should show the updated TOC analysis preferences" do
        input << 1 ; input << 2 ; input << 1 # cuesheet
        input << 2 #single file
        input << 3 #hidden sectors
        input << 4 ; input << 5 # seconds hidden tracks
        input << 5 ; input << 2 # append
        input << 6 ; input << 2 # sox
        start()
        output.should be_visible(" 1) Create a cuesheet [ ]")
        output.should be_visible(" 2) Rip to single file [*]")
        output.should be_visible(" 3) Rip hidden audio sectors [ ]")
        output.should be_visible(" 4) Minimum seconds hidden track: 5")
        output.should be_visible(" 5) Append or prepend audio: append")
        output.should be_visible(" 6) Way to handle pre-emphasis: sox")
      end

      it "should show the updated the codecs preferences" do
        input << 1 ; input << 3 ; input << 1 # flac
        input << 2 ; input << '--good' # flac settings
        input << 3  # vorbis
        input << 4 ; input << '-q 5' # vorbis settings
        input << 5 ; # mp3
        input << 6 ; input << '-V 2'
        input << 7  # wav
        input << 8 # other
        input << 9 ; input << 'flac %i %o.flac' #other command
        input << 10 # playlist
        input << 11 ; input << 3 # threads
        input << 12 # noSpaces
        input << 13 # noCapitals
        input << 14 ; input << 2 # normalizer
        input << 15 ; input << 2 # track based
        start()
        output.should be_visible(" 1) Flac [*]")
        output.should be_visible(" 2) Flac options passed: --good")
        output.should be_visible(" 3) Vorbis [ ]")
        output.should be_visible(" 4) Oggenc options passed: -q 5")
        output.should be_visible(" 5) Mp3 [*]")
        output.should be_visible(" 6) Lame options passed: -V 2")
        output.should be_visible(" 7) Wav [*]")
        output.should be_visible(" 8) Other codec [*]")
        output.should be_visible(" 9) Commandline passed: flac %i %o.flac")
        output.should be_visible("10) Playlist support [ ]")
        output.should be_visible("11) Maximum extra encoding threads: 3")
        output.should be_visible("12) Replace spaces with underscores [*]")
        output.should be_visible("13) Downsize all capital letters in filenames [*]")
        output.should be_visible("14) Normalize program: replaygain")
        output.should be_visible("15) Normalize modus: track")
      end

      it "should show the updated the freedb preferences" do
        input << 1 ; input << 4 ; input << 1 # use freedb
        input << 2 # first hit
        input << 3 ; input << 'http://google.nl' # freedb server
        input << 4 ; input << 'Joe' #freedb username
        input << 5 ; input << 'Black' # freedb hostname
        start()
        output.should be_visible(" 1) Fetch cd info with freedb [*]")
        output.should be_visible(" 2) Always use first hit [*]")
        output.should be_visible(" 3) Freedb server: http://freedb.freedb.org/~cddb/cddb.cgi")
        output.should be_visible(" 4) Freedb username: anonymous")
        output.should be_visible(" 5) Freedb hostname: my_secret.com")
      end

      it "should show the updated other preferences" do
        input << 1 ; input << 5 # go to other menu
        input << 1 ; input << '/home/test2' # basedir
        input << 2 ; input << '%f/BE_HAPPY/%a %b %y/%n - %t' # standard filescheme
        input << 3 ; input << '%f/BE_HAPPY/%va %b %y' # var filescheme
        input << 4 ; input << '%f/BE_HAPPY/%a %b %y/%n - %t' # single filescheme
        input << 5 ; input << 'gedit' # log file viewer
        input << 6 ; input << 'dolphin' # file browser
        input << 7 # verbose mode
        input << 8 # debug mode
        start()
        output.should be_visible(" 1) Base directory: /home/test2")
        output.should be_visible(" 2) Standard filescheme: %f/BE_HAPPY/%a %b %y/%n - %t")
        output.should be_visible(" 3) Various artist filescheme: %f/BE_HAPPY/%va %b %y")
        output.should be_visible(" 4) Single file rip filescheme: %f/BE_HAPPY/%a %b %y/%n - %t")
        output.should be_visible(" 5) Log file viewer: gedit")
        output.should be_visible(" 6) File manager: dolphin")
        output.should be_visible(" 7) Verbose mode [*]")
        output.should be_visible(" 8) Debug mode [*]")
      end
  end
  after(:all) do ; $TST_DEFAULT_PREFS = false ; end
end
