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

require 'rubyripper/checkConfigBeforeRipping.rb'

# The main program is launched from the class Rubyripper
class Rubyripper
attr_reader :outputDir

  # * preferences = The preferences object
  # * userInterface = the user interface object (with the update function)
  # * disc = the disc object
  # * trackSelection = an array with selected tracks
	def initialize(preferences, userInterface, disc, trackSelection)
		@prefs = preferences
		@update = userInterface
		@disc = disc
		@trackSelection = trackSelection
	end
	
	# check if all is ready to go
	def checkConfiguration
	  @helper = CheckConfigBeforeRipping.new(@prefs, @update, @disc, @trackSelection)
	  return @helper.result
	end
	
	def startRip
	  autofixCommonMistakes()
 		@prefs['cd'].md.saveChanges()
		@prefs['Out'] = OutputFile.new(@prefs)
		@prefs['log'] = Log.new(@prefs)
		@outputDir = @prefs['Out'].getDir()
		updateGui() # Give some info about the cdrom-player, the codecs, the ripper, cddb_info

		waitForToc()

		@prefs['log'].add(_("\nSTATUS\n\n"))

		computePercentage() # Do some pre-work to get the progress updater working later on
		require 'digest/md5' # Needed for secure class, only have to load them ones here.
		@encoding = Encode.new(@prefs) #Create an instance for encoding
		@ripping = SecureRip.new(@prefs, @encoding) #create an instance for ripping
	end
	
	def autofixCommonMistakes
		flacIsNotAllowedToDeleteInputFile() if @prefs.flac
		repairOtherPrefs() if @prefs.other
		rippingErrorSectorsMustAtLeasEqualRippingNormalSectors()
	end
	
	 # filter out encoding flags that do non-encoding tasks
	def flacIsNotAllowedToDeleteInputFile
		@prefs.settingsFlac = @prefs.settingsFlac.gsub(' --delete-input-file', '')
	end
	
	def repairOtherprefs
		copyString = ""
		lastChar = ""

		#first remove all double quotes. then iterate over each char
		@prefs.settingsOther.delete('"').split(//).each do |char|
			if char == '%' # prepend double quote before %
				copyString << '"' + char
			elsif lastChar == '%' # append double quote after %char
				copyString << char + '"'
			else
				copyString << char
			end
			lastChar = char
		end

		# above won't work for various artist
		copyString.gsub!('"%v"a', '"%va"')

		@prefs.settingsOther = copyString
		puts @prefs.settingsOther if @prefs['debug']
	end
	
	def rippingErrorSectorsMustAtLeasEqualRippingNormalSectors()
	  if @prefs.reqMatchesErrors < @prefs.reqMatchesAll
	    @prefs.reqMatchesErrors = @prefs.reqMatchesAll
	  end
	end

	# original init
	#def backupInit
	#	@directory = false
	#	@prefs['log'] = false
	#	@prefs['instance'] = gui
	#	@error = false
	#	@encoding = nil
	#	@ripping = nil
	#end

	# the user wants to abort the ripping
	def cancelRip
		puts "User aborted current rip"
		`killall cdrdao 2>&1`
		@encoding.cancelled = true if @encoding != nil
		@encoding = nil
		@ripping.cancelled = true if @ripping != nil
		@ripping = nil
		`killall cdparanoia 2>&1` # kill any rip that is already started
	end

	# wait for the Advanced Toc class to finish
	# cdrdao takes a while to finish reading the disc
	def waitForToc
		if @prefs['create_cue'] && installed('cdrdao')
			@prefs['log'].add(_("\nADVANCED TOC ANALYSIS (with cdrdao)\n"))
			@prefs['log'].add(_("...please be patient, this may take a while\n\n"))

			@prefs['cd'].updateprefs(@prefs) # update the rip prefs

			@prefs['cd'].toc.log.each do |message|
				@prefs['log'].add(message)
			end
		end
	end

	def summary
		return @prefs['log'].short_summary
	end

	def postfixDir
		@prefs['Out'].postfixDir()
	end

	def overwriteDir
		@prefs['Out'].overwriteDir()
	end

	def updateGui
		@prefs['log'].add(_("Cdrom player used to rip:\n%s\n") % [@prefs['cd'].devicename])
		@prefs['log'].add(_("Cdrom offset used: %s\n\n") % [@prefs['offset']])
		@prefs['log'].add(_("Ripper used: cdparanoia %s\n") % [if @prefs['ripperprefs'] ; @prefs['ripperprefs'] else _('default prefs') end])
		@prefs['log'].add(_("Matches required for all chunks: %s\n") % [@prefs['req_matches_all']])
		@prefs['log'].add(_("Matches required for erroneous chunks: %s\n\n") % [@prefs['req_matches_errors']])

		@warnings.each{|warning| @prefs['log'].add(warning)}
		@prefs['log'].add(_("Codec(s) used:\n"))
		if @prefs['flac']; @prefs['log'].add(_("-flac \t-> %s (%s)\n") % [@prefs['flacprefs'], `flac --version`.strip]) end
		if @prefs['vorbis']; @prefs['log'].add(_("-vorbis\t-> %s (%s)\n") % [@prefs['vorbisprefs'], `oggenc --version`.strip]) end
		if @prefs['mp3']; @prefs['log'].add(_("-mp3\t-> %s\n(%s\n") % [@prefs['mp3prefs'], `lame --version`.split("\n")[0]]) end
		if @prefs['wav']; @prefs['log'].add(_("-wav\n")) end
		if @prefs['other'] ; @prefs['log'].add(_("-other\t-> %s\n") % [@prefs['otherprefs']]) end
		@prefs['log'].add(_("\nCDDB INFO\n"))
		@prefs['log'].add(_("\nArtist\t= "))
		@prefs['log'].add(@prefs['cd'].md.artist)
		@prefs['log'].add(_("\nAlbum\t= "))
		@prefs['log'].add(@prefs['cd'].md.album)
		@prefs['log'].add(_("\nYear\t= ") + @prefs['cd'].md.year)
		@prefs['log'].add(_("\nGenre\t= ") + @prefs['cd'].md.genre)
		@prefs['log'].add(_("\nTracks\t= ") + @prefs['cd'].audiotracks.to_s +
		" (#{@prefs['tracksToRip'].length} " + _("selected") + ")\n\n")
		@prefs['cd'].audiotracks.times do |track|
			if @prefs['tracksToRip'] == 'image' || @prefs['tracksToRip'].include?(track + 1)
				@prefs['log'].add("#{sprintf("%02d", track + 1)} - #{@prefs['cd'].md.tracklist[track]}\n")
			end
		end
	end

	def computePercentage
		@prefs['percentages'] = Hash.new() #progress for each track
		totalSectors = 0.0 # It can be that the user doesn't want to rip all tracks, so calculate it
		@prefs['tracksToRip'].each{|track| totalSectors += @prefs['cd'].getLengthSector(track)} #update totalSectors
		@prefs['tracksToRip'].each{|track| @prefs['percentages'][track] = @prefs['cd'].getLengthSector(track) / totalSectors}
	end
end
