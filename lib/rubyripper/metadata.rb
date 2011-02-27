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

# This class is responsible for getting all metadata of the disc and tracks
class Metadata

  # setting up all necessary objects
  def initialize(preferences, disc, deps=nil)
    @prefs = preferences
    @disc = disc
    @deps = deps
  end

  # get the metadata for the disc
  def get
    isLocalFileFound?
  end

  # tryLocalFirst
  def isLocalFileFound?
    require 'rubyripper/freedb/loadFreedbRecord'
    @load = LoadFreedbRecord.new()
    @load.scan(@disc.discid)
    if @load.freedbRecord != nil && @load.status == 'ok'
      @load.freedbRecord
    end
  end
end
# 		@status = 'ok'
# 		@metadata = Hash.new()
# 		setDefaultTags()
# 		getFreedbString()
# 		findMetadata()
# 	end
#
# 	# return the status
# 	def status ; return @status ; end
#
# 	# return a string with the artist
# 	def artist ; return getInfo('artist') ; end
#
# 	# set the artist to a new string
# 	def artist=(string); @metadata['artist'] = string ; end
#
# 	# return a string with the album
# 	def album ; return getInfo('album') ; end
#
# 	# set the album to a new string
# 	def album=(string); @metadata['album'] = string ; end
#
# 	# return a string with the year
# 	def year ; return getInfo('year') ;	end
#
# 	# set the year to a new string
# 	def year=(string); @metadata['year'] = string ; end
#
# 	# return a string with the genre
# 	def genre ; return getInfo('genre') ; end
#
# 	# set the genre to a new string
# 	def genre=(string); @metadata['genre'] = string ; end
#
# 	# return a hash with strings with the trackname for each number
# 	def tracklist ; return getInfo('tracklist') ; end
#
# 	# return extra disc info, false if unknown
# 	def extraDiscInfo ; return getInfo('extraDiscInfo') ; end
#
# 	# return a hash with strings with the artist for each number, false if unknown
# 	def varArtists ; return getInfo('varArtist') ; end
#
# 	# return a trackname for a number, false if unknown
# 	def trackname(number)
# 		return getInfo('tracklist')[number]
# 	end
#
# 	# set the trackname for a number
# 	def setTrackname(number, string)
# 		@metadata['tracklist'][number] = string
# 	end
#
# 	# return the artist for the number, false if unknown
# 	def varArtist(number)
# 		return getInfo('varArtist')[number]
# 	end
#
# 	# set the artist for a number
# 	def setVarArtist(number, string)
# 		@metadata['varArtist'][number] = string
# 	end
#
# private
#
# 	# return the key of if not found the default
# 	def getInfo(key, default=false)
# 		if @metadata.key?(key)
# 			return @metadata[key]
# 		else
# 			return default
# 		end
# 	end
#
# 	# before doing any attempts at getting extra metadata set the defaults
# 	def setDefaultTags
# 		@metadata['artist'] = _('Unknown')
# 		@metadata['album'] = _('Unknown')
# 		@metadata['genre'] = _('Unknown')
# 		@metadata['year'] = '0'
#
# 		@metadata['tracklist'] = Hash.new
# 		(1..@disc.getInfo('audiotracks')).each do |track|
# 			@metadata['tracklist'][track] = _("Track %s") % [track]
# 		end
# 	end
#
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
