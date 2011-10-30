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

require 'rubyripper/preferences/main'
require 'rubyripper/system/dependency'
require 'rubyripper/system/execute'
require 'rubyripper/permissionDrive'
require 'rubyripper/disc/scanDiscCdparanoia'
require 'rubyripper/disc/scanDiscCdinfo'
require 'rubyripper/disc/scanDiscCdcontrol'
require 'rubyripper/disc/freedbString'

# TODO point to cdparanoia with ruby magic instead of copying functions
class Disc
attr_reader :metadata

  # initialize all needed dependencies
  def initialize(exec=nil, perm=nil, cdpar=nil, cdinfo=nil, cdcontrol=nil, freedb=nil, prefs=nil, deps=nil)
    @deps = deps ? deps : Dependency.instance
    @exec = exec ? exec : Execute.new()
    @perm = perm ? perm : PermissionDrive.new()
    @cdpar = cdpar ? cdpar : ScanDiscCdparanoia.new(@exec, @perm)
    @cdinfo = cdinfo ? cdinfo : ScanDiscCdinfo.new(@exec)
    @cdcontrol = cdcontrol ? cdcontrol : ScanDiscCdcontrol.new(@exec)
    @freedb = freedb ? freedb : FreedbString.new(@cdpar, @exec, @cdinfo, @cdcontrol)
    @prefs = prefs ? prefs : Preferences::Main.instance
  end

  # after a succesfull scan setup the metadata object
  def scan
    @cdpar.scan
    setMetadata() if @cdpar.status == 'ok'
  end

  # helper functions for ScanDiscCdparanoia
  def status ; @cdpar.status ; end
  def error ; @cdpar.error ; end
  def playtime ; @cdpar.playtime ; end
  def audiotracks ; @cdpar.audiotracks ; end
  def devicename ; @cdpar.devicename ; end
  def firstAudioTrack ; @cdpar.firstAudioTrack ; end
  def getStartSector(track) ; @cdpar.getStartSector(track) ; end
  def getLengthSector(track) ; @cdpar.getLengthSector(track) ; end
  def getLengthText(track) ; @cdpar.getLengthText(track) ; end
  def getFileSize(track) ; @cdpar.getFileSize(track) ; end
  def multipleDriveSupport ; @cdpar.multipleDriveSupport ; end

  # helper functions for @freedb
  def freedbString ; @freedb.freedbString ; end
  def discid ; @freedb.discid ; end

  # helper method to return the metadata
  private

  # helper function to load metadata object
  def setMetadata
    require 'rubyripper/freedb'
    @metadata = Freedb.new(self)
    @metadata.get()
  end
end

# private
#
# 	# use cdrdao to scan for exact pregaps, hidden tracks, pre_emphasis
# 	def prepareToc
# 		if @settings['create_cue'] && @deps.installed?('cdrdao')
# 			@cdrdaoThread = Thread.new{advancedToc()}
# 		elsif @settings['create_cue']
# 			puts "Cdrdao not found. Advanced TOC analysis / cuesheet is skipped."
# 			@settings['create_cue'] = false # for further assumptions later on
# 		end
# 	end
#
# 	# start the Advanced toc instance
# 	def advancedToc
# 		@tocStarted = true
# 		@toc = ScanDiscCdrdao.new(@settings)
# 	end
#
# 	# update the Disc class with actual settings and make a cuesheet
# 	def updateSettings(settings)
# 		@settings = settings
#
# 		# user may have enabled cuesheet after the disc was scanned
# 		# @toc is still nil because the class isn't finished yet
# 		prepareToc() if @tocStarted == false
#
# 		# if the scanning thread is still active, wait for it to finish
# 		@cdrdaoThread.join() if @cdrdaoThread != nil
#
# 		# update the length of the sectors + the start of the tracks if we're
# 		# prepending the gaps
# 		# also for the image since this is more easy with the cuesheet handling
# 		if @settings['pregaps'] == "prepend" || @settings['image']
# 			prependGaps()
# 		end
#
# 		# only make a cuesheet when the toc class is there
# 		@cue = Cuesheet.new(@settings, @toc) if @toc != nil
# 	end
# endrequire 'rubyripper/disc'
#
# #		if @disc.freedbString != @disc.oldFreedbString # Scanning the same disc will always result in an new freedb fetch.
# #			if @metadataFile.has_key?(@disc.freedbString) || findLocalMetadata #is the Metadata somewhere local?
# #				if @metadataFile.has_key?(@disc.freedbString)
# #					@rawResponse = @metadataFile[@disc.freedbString]
# #				end
# #				@tracklist.clear()
# #				handleResponse()
# #				@status = true # Give the signal that we're finished
# #				return true
# #			end
# #		end
# #
# #		if @verbose ; puts "preparing to contact freedb server" end
# #		handshake()
# #	end
