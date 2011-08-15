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

require 'rubyripper/dependency.rb'

# some sanity checks before the ripping starts
class CheckConfigBeforeRipping
  # * preferences = The preferences object
  # * userInterface = the user interface object (with the update function)
  # * disc = the disc object
  # * trackSelection = an array with selected tracks
  def initialize(preferences, userInterface, disc, trackSelection)
    @prefs = preferences
    @ui = userInterface
    @disc = disc
    @trackSelection = trackSelection
    @deps = Dependency.new()
    @errors = Array.new
  end

  # Give the result for the checks
  def result
    checkPreferences()
    checkUserInterface()
    checkDisc()
    checkTrackSelection()
    checkBinaries()
    return @errors
  end

private
  def addError(code, parameters=nil)
    @errors << [code, parameters]
  end

  def checkPreferences
    checkDevice()
    checkMinOneCodec()
  end

  def checkDevice
    if !(File.symlink?(@prefs.cdrom) || File.blockdev?(@prefs.cdrom))
      addError(:unknownDrive, @prefs.cdrom)
    end
  end

	def checkMinOneCodec()
	  unless @prefs.flac || @prefs.vorbis || @prefs.mp3 || @prefs.wav || @prefs.other
	    addError(:noCodecSelected)
 		end
	end

	def checkUserInterface
	  addError(:noValidUserInterface) unless @ui.respond_to?(:update)
	end

	def checkDisc
	  addError(:noDiscInDrive, @prefs.cdrom) if @disc.status != 'ok'
	end

	# notice that image rips don't require track selection
	def checkTrackSelection
	  if !@prefs.image && @trackSelection.empty?
	    addError(:noTrackSelection)
	  end
	end

  def checkBinaries
    isFound?('cdparanoia')
    isFound?('flac') if @prefs.flac
    isFound?('oggenc') if @prefs.vorbis
    isFound('lame') if @prefs.mp3
    isFound('normalize') if @prefs.normalizer == 'normalize'

    if @prefs.normalizer == 'replaygain'
      isFound?('metaflac') if @prefs.flac
      isFound?('vorbisgain') if @prefs.vorbis
      isFound?('mp3gain') if @prefs.mp3
      isFound?('wavegain') if @prefs.wav
    end
  end

  def isFound?(binary)
    if !@deps.installed?(binary)
      addError(:binaryNotFound, binary.capitalize)
    end
  end
end

		#TODO
		#if (!@prefs['cd'].tocStarted || @prefs['cd'].tocFinished)
		#	temp = AccurateScanDisc.new(@prefs, @prefs['instance'], '', true)
		#	if @prefs['cd'].freedbString != temp.freedbString || @prefs['cd'].playtime != temp.playtime
		#		@error = ["error", _("The Gui doesn't match inserted cd. Please press Scan Drive first.")]
 		#		return false
		#	end
		#end

    #TODO
		# update the ripping prefs for a hidden audio track if track 1 is selected
		#if @prefs['cd'].getStartSector(0) && @prefs['tracksToRip'][0] == 1
		#	@prefs['tracksToRip'].unshift(0)
		#end
