#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/preferences/main'
require 'rubyripper/system/dependency'
require 'rubyripper/metadata/freedb/loadFreedbRecord'
require 'rubyripper/metadata/freedb/saveFreedbRecord'
require 'rubyripper/metadata/freedb/freedbRecordParser'
require 'rubyripper/metadata/freedb/getFreedbRecord'
require 'rubyripper/metadata/data'

# This class is responsible for getting all metadata of the disc and tracks
class Freedb

  # setting up all necessary objects
  def initialize(disc, loadFreedbRecord=nil, save=nil, md=nil, parser=nil, getFreedb=nil, prefs=nil, deps=nil)
    @disc = disc
    @loadFreedbRecord = loadFreedbRecord ? loadFreedbRecord : LoadFreedbRecord.new()
    @prefs = prefs ? prefs : Preferences::Main.instance
    @deps = deps ? deps : Dependency.instance()
    @save = save ? save : SaveFreedbRecord.new()
    @md = md ? md : Metadata::Data.new()
    @parser = parser ? parser : FreedbRecordParser.new(@md)
    @getFreedb = getFreedb ? getFreedb : GetFreedbRecord.new()
  end

  # get the metadata for the disc
  def get()
    case
      when isLocalFileFound? then handleLocal()
      when isRemoteFileFound? then handleRemote()
    end
  end

  # helper function for the freedbrecordparser class
  def undoVarArtist ; @parser.undoVarArtist ; end
  def redoVarArtist ; @parser.redoVarArtist ; end

  private

  # if the method is not found try to look it up in the data object
  def method_missing(name, *args)
    @md.send(name, *args)
  end

  def isLocalFileFound?
    if @prefs.testdisc
      @loadFreedbRecord.read(@prefs.testdisc)
    else
      @loadFreedbRecord.scan(@disc.freedbDiscid)
    end
    
    @loadFreedbRecord.freedbRecord != nil && @loadFreedbRecord.status == 'ok'
  end

  def handleLocal
    @parser.parse(@loadFreedbRecord.freedbRecord)
  end

  def isRemoteFileFound?
    @getFreedb.queryDisc(@disc.freedbString)
    @getFreedb.status =~ /ok|multipleRecords/
  end

  # always save the file first and reload it (to fix encoding errors)
  def handleRemote()
    if @getFreedb.status == 'ok'
      @save.save(@getFreedb.freedbRecord, @getFreedb.category, @disc.freedbDiscid)
      get()
    else
      #multiple records
    end
  end
end
