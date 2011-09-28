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

require 'rubyripper/system/dependency'
require 'rubyripper/freedb/loadFreedbRecord'
require 'rubyripper/freedb/saveFreedbRecord'
require 'rubyripper/freedb/freedbRecordParser'
require 'rubyripper/freedb/getFreedbRecord'
require 'rubyripper/freedb/metadata'

# This class is responsible for getting all metadata of the disc and tracks
class Freedb

  # setting up all necessary objects
  def initialize(disc, prefs, deps=nil, load=nil, save=nil, md=nil, parser=nil, getFreedb=nil)
    @disc = disc
    @prefs = prefs
    @deps = deps ? deps : Dependency.new()
    @load = load ? load : LoadFreedbRecord.new()
    @save = save ? save : SaveFreedbRecord.new()
    @md = md ? md : Metadata.new()
    @parser = parser ? parser : FreedbRecordParser.new(@md)
    @getFreedb = getFreedb ? getFreedb : GetFreedbRecord.new(@prefs)
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
    @load.scan(@disc.discid)
    @load.freedbRecord != nil && @load.status == 'ok'
  end

  def handleLocal ; @parser.parse(@load.freedbRecord) ; end

  def isRemoteFileFound?
    @getFreedb.queryDisc(@disc.freedbString)
    @getFreedb.status =~ /ok|multipleRecords/
  end

  # always save the file first and reload it (to fix encoding errors)
  def handleRemote()
    if @getFreedb.status == 'ok'
      @save.save(@getFreedb.freedbRecord, @getFreedb.category, @disc.discid)
      get()
    else
      #multiple records
    end
  end
end

# 	# read the freedb string from the helper class
# 	def getFreedbString
# 		disc = FreedbString.new(@deps, @settings, @disc)
# 		@freedbString = disc.getFreedbString()
# 		@discId = disc.getDiscId()
# 	end
#
# 	# try to find local Cddb files first
# 	def findMetadata
# 		local = LoadFreedbRecord.new(@discId)
# 		if @freshCopy == false && local.status == 'ok'
# 			@freedbRecord = local.freedbRecord
# 		else
# 			getFreedb()
# 		end
# 	end
#
# 	# get the information from the freedb server
# 	def getFreedb
# 		require 'rubyripper/freedb/getFreedbRecord.rb'
# 		require 'rubyripper/freedb/cgiHttpHandler.rb'
# 		@remote = GetFreedbRecord.new(@freedbString, @settings,
# CgiHttpHandler.new(@settings))
#
# 		if @remote.status[0] == 'ok'
# 			@freedbRecord = @remote.freedbRecord
# 			require 'rubyripper/freedb/saveFreedbRecord.rb'
# 			SaveFreedbRecord.new(@freedbRecord, @remote.category, @remote.discId)
# 			@freedbRecord = LoadFreedbRecord.new(@remote.discId).freedbRecord
# 			updateMetadata()
# 		else
# 			puts @remote.status[0]
# 			@status = @remote.status[0]
# 		end
# 	end
#
# 	# add the freedb info
# 	def updateMetadata
# 		@freedb = FreedbRecordParser.new(@freedbRecord)
# 		if @freedb.status == 'ok'
# 			@metadata.merge!(@freedb.metadata)
# 		else
# 			puts @freedb.status
# 		end
# 	end
# end
