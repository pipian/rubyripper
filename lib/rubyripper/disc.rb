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
require 'rubyripper/fireCommand'
require 'rubyripper/permissionDrive'
require 'rubyripper/disc/scanDiscCdparanoia'
require 'rubyripper/disc/scanDiscCdinfo'
require 'rubyripper/disc/freedbString'

class Disc

  # initialize all needed dependencies
  def initialize(preferences, deps=nil, fire=nil, perm=nil, cdpar=nil, cdinfo=nil, freedb=nil)
    @prefs = preferences
    @deps = deps ? deps : Dependency.new
    @fire = fire ? fire : FireCommand.new(@deps)
    @perm = perm ? perm : PermissionDrive.new
    @cdpar = cdpar ? cdpar : ScanDiscCdparanoia.new(@fire, @perm, @prefs)
    @cdinfo = cdinfo ? cdinfo : ScanDiscCdinfo.new(@prefs, @fire)
    @freedb = freedb ? freedb : FreedbString.new(@deps, @prefs, @cdpar, @fire, @cdinfo)
  end

  # helper functions for ScanDiscCdparanoia
  def scan ; @cdpar.scan ; end
  def status ; @cdpar.status ; end
  def playtime ; @cdpar.playtime ; end
  def audiotracks ; @cdpar.audiotracks ; end
  def devicename ; @cdpar.devicename ; end
  def firstAudioTrack ; @cdpar.firstAudioTrack ; end
  def getStartSector(track) ; @cdpar.getStartSector(track) ; end
  def getLengthSector(track) ; @cdpar.getLengthSector(track) ; end
  def getLengthText(track) ; @cdpar.getLengthText(track) ; end
  def getFileSize(track) ; @cdpar.getFileSize(track) ; end

  # helper functions for @freedb
  def freedbString ; @freedb.freedbString ; end
  def discid ; @freedb.discid ; end

  # helper function to load metadata object
  def metadata
    require 'rubyripper/metadata'
    @metadata = Metadata.new(@prefs, self, @deps)
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
