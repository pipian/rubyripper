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

require 'singleton'
require 'rubyripper/preferences/data'
require 'rubyripper/preferences/cleanup'
require 'rubyripper/preferences/setDefaults'
require 'rubyripper/preferences/load'
require 'rubyripper/preferences/save'

module Preferences

  class Main
    include Singleton unless $run_specs
    
    attr_reader :data
    attr_accessor :filename

    def initialize(out=nil)
      @data = Data.new
      @filename = getDefaultFilename()
      @out = out ? out : $stdout
    end

    # load the preferences after setting the defaults
    def load(customFilename="")
      Cleanup.new()
      SetDefaults.new()
      Load.new(customFilename, @out)
    end

    # save the preferences
    def save()
      Save.new() unless @data.testdisc
    end

   private

    # if the method is not found try to look it up in the data object
    def method_missing(name, *args)
      @data.send(name, *args)
    end

    # return the default filename
    def getDefaultFilename
      dir = ENV['XDG_CONFIG_HOME'] || File.join(ENV['HOME'], '.config')
      File.join(dir, 'rubyripper/settings')
    end
  end

  # A separate help function to make it faster
  def self.showFilenameNormal(basedir, layout)
    filename = File.expand_path(File.join(basedir, layout))
    filename = _("Example filename: %s.ext") % [filename]
    {'%a' => 'Judas Priest', '%b' => 'Sin After Sin', '%f' => 'codec',
    '%g' => 'Rock', '%y' => '1977', '%n' =>'01', '%t' => 'Sinner',
    '%i' =>'inputfile', '%o' => 'outputfile'}.each do |key, value|
        filename.gsub!(key,value)
    end
    return filename
  end

  # A separate help function to make it faster
  def self.showFilenameVarious(basedir, layout)
    filename = File.expand_path(File.join(basedir, layout))
    filename = _("Example filename: %s.ext") % [filename]
    {'%va' => 'Various Artists', '%b' => 'TMF Rockzone', '%f' => 'codec',
    '%g' => "Rock", '%y' => '1999', '%n' => '01', '%a' => 'Kid Rock',
    '%t' => 'Cowboy'}.each do |key, value|
        filename.gsub!(key,value)
    end
    return filename
  end
end
