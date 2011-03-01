#!/usr/bin/env ruby
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

require 'rubyripper/dependency'

# The settings class is responsible for:
# managing the settings during a session
class HandlePrefs
  attr_reader :prefs

  # setup the instances
  def initialize(deps=nil)
    @deps = deps ? deps : Dependency.new
    @prefs = Hash.new()
  end

  # return the preference
  def get(preference)
    if @prefs.key?(preference)
      return @prefs[preference]
    else
      puts "WARNING: #{preference} key does not exist! (get preferences)"
      return nil
    end
  end

  # set the preference
  def set(preference, value)
    if @prefs.key?(preference)
      @prefs[preference] = value
    else
      puts "WARNING: #{preference} key does not exist! (set preferences)"
      return nil
    end
  end

  # setup the the default settings
  def setDefaults
    @prefs = {"flac" => false,
      "settingsFlac" => "--best -V", #passed to flac
      "vorbis" => true,
      "settingsVorbis" => "-q 4", #passed to vorbis
      "mp3" => false,
      "settingsMp3" => "-V 3 --id3v2-only", #passed to lame
      "wav" => false,
      "other" => false, #any other codec
      "settingsOther" => '', #the complete command
      "playlist" => true,
      "cdrom" => @deps.cdrom,
      "offset" => 0,
      "maxThreads" => 2, #number of encoding proces while ripping
      "rippersettings" => '', #passed to cdparanoia
      "maxTries" => 5, #number of tries before giving up correcting
      'basedir' => '~/', #where to store your new rips?
      'namingNormal' => '%f/%a (%y) %b/%n - %t', # normal discs
      'namingVarious' => '%f/%va (%y) %b/%n - %a - %t', # various artist discs
      'namingImage' => '%f/%a (%y) %b/%a - %b (%y)', # image rips
      "verbose" => false, # extra info shown in terminal
      "debug" => true, # extra debug info shown in terminal
      "eject" => true, # open up the tray when finished?
      'ripHiddenAudio' => true, # rip part before track 1?
      'minLengthHiddenTrack' => 2, #minimum seconds hidden track
      "reqMatchesErrors" => 2, # # required matches when errors detected
      "reqMatchesAll" => 2,  # required matches when no errors detected
      "site" => "http://freedb.freedb.org/~cddb/cddb.cgi", # freedb site
      "username" => "anonymous", # user name freedb
      "hostname" => "my_secret.com", # hostname freedb
      "firstHit" => true, # always choose 1st option
      "freedb" => true, # enable freedb
      "editor" => @deps.editor, #default editor
      "filemanager" => @deps.filemanager, #default file manager
      "browser" => @deps.browser, #default browser
      "noLog" => false, #delete log if no errors?
      "createCue" => true, #create cuesheet
      "image" => false, #save to single file
      'normalizer' => 'none', #normalize volume?
      'gain' => "album", #gain mode
      'gainTagsOnly' => false, #not actually modify audio
      'noSpaces' => false, #replace spaces with underscores
      'noCapitals' => false, #replace uppercase with lowercase
      'preGaps' => "prepend", #way to handle pregaps
      'preEmphasis' => 'cue' #way to handle pre-emphasis
    }
  end

  # update the settings with the info from loadPrefs
  # also check if @load has all the keys
  def update(results)
    results.each do |key, value|
      if @prefs.key?(key)
        @prefs[key] = value
      else
        puts "WARNING: invalid setting: #{key}"
      end
    end

    results.each do |key, value|
      if results[key].nil?
        puts "WARNING: #{key} is missing in config file!"
      end
    end
  end
end

