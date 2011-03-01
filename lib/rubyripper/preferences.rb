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
require 'rubyripper/fileAndDir'
require 'rubyripper/preferences/loadPrefs'
require 'rubyripper/preferences/savePrefs'
require 'rubyripper/preferences/cleanPrefs'
require 'rubyripper/preferences/handlePrefs'

# This class handles the preferences. It abstracts the detailed
# helpclasses for the main program.
class Preferences

  # setup the instances
  def initialize(dependency=nil, fileAndDir=nil, loadPrefs=nil,
                 savePrefs=nil, cleanPrefs=nil, handlePrefs=nil)

    @deps = dependency ? dependency : Dependency.new
    @file = fileAndDir ? fileAndDir : FileAndDir.new
    @load = loadPrefs ? loadPrefs : LoadPrefs.new(@file)
    @save = savePrefs ? savePrefs : SavePrefs.new(@file)
    @clean = cleanPrefs ? cleanPrefs : CleanPrefs.new(@file)
    @handle = handlePrefs ? handlePrefs : HandlePrefs.new(@deps)
  end

  # The standard configfile
  def defaultConfigFile
    dir = ENV['XDG_CONFIG_HOME'] || File.join(ENV['HOME'], '.config')
    File.join(dir, 'rubyripper/settings')
  end

  # Since the program starts by loading the preferences, this is
  # the right moment to have some initializing
  def load(configFile)
    @handle.setDefaults()
    @clean.cleanup()
    @load.parseFile(defaultConfigFile, configFile)
    @handle.update(@load.results)
    save()
  end

  def get(preference) ; @handle.get(preference) ; end
  def set(preference, value) ; @handle.set(preference, value) ; end
  def save ; @save.save(@handle.prefs, @load.configFile) ; end
  def configFound? ; @load.configFound ; end
end

