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

# The main program is launched from the class Rubyripper

class Rubyripper
attr_reader :outputDir

	def initialize(settings, gui)
		@settings = settings.dup
		@directory = false
		@settings['log'] = false
		@settings['instance'] = gui
		@error = false
		@encoding = nil
		@ripping = nil
		@warnings = Array.new
	end

	def settingsOk
		if not checkConfig() ; return @error end
		if not testDeps() ; return @error end
		getWarnings()
		@settings['cd'].md.saveChanges()
		@settings['Out'] = OutputFile.new(@settings)
		return @settings['Out'].status
	end

	def startRip
		@settings['log'] = Log.new(@settings)
		@outputDir = @settings['Out'].getDir()
		updateGui() # Give some info about the cdrom-player, the codecs, the ripper, cddb_info

		waitForToc()

		@settings['log'].add(_("\nSTATUS\n\n"))

		computePercentage() # Do some pre-work to get the progress updater working later on
		require 'digest/md5' # Needed for secure class, only have to load them ones here.
		@encoding = Encode.new(@settings) #Create an instance for encoding
		@ripping = SecureRip.new(@settings, @encoding) #create an instance for ripping
	end

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
		if @settings['create_cue'] && installed('cdrdao')
			@settings['log'].add(_("\nADVANCED TOC ANALYSIS (with cdrdao)\n"))
			@settings['log'].add(_("...please be patient, this may take a while\n\n"))

			@settings['cd'].updateSettings(@settings) # update the rip settings

			@settings['cd'].toc.log.each do |message|
				@settings['log'].add(message)
			end
		end
	end

	# check the configuration of the user.
	# 1) does the ripping drive exists
	# 2) are there tracks selected to rip
	# 3) is the current disc the same as loaded in memory
	# 4) is at least one codec is selected
	# 5) are the otherSettings correct
	# 6) is req_matches_all <= req_matches_errors

	def checkConfig
		unless File.symlink?(@settings['cdrom']) || File.blockdev?(@settings['cdrom'])
			@error = ["error", _("The device %s doesn't exist on your system!") % [@settings['cdrom']]]
			return false
		end

		if @settings['tracksToRip'].size == 0
			@error = ["error", _("Please select at least one track.")]
			return false
		end

		if (!@settings['cd'].tocStarted || @settings['cd'].tocFinished)
			temp = AccurateScanDisc.new(@settings, @settings['instance'], '', true)
			if @settings['cd'].freedbString != temp.freedbString || @settings['cd'].playtime != temp.playtime
				@error = ["error", _("The Gui doesn't match inserted cd. Please press Scan Drive first.")]
 				return false
			end
		end

		unless @settings['flac'] || @settings['vorbis'] || @settings['mp3'] || @settings['wav'] || @settings['other']
			@error = ["error", _("No codecs are selected!")]
			return false
 		end

		# filter out encoding flags that do non-encoding tasks
		@settings['flacsettings'].gsub!(' --delete-input-file', '')

		if @settings['other'] ; checkOtherSettings() end

		# update the ripping settings for a hidden audio track if track 1 is selected
		if @settings['cd'].getStartSector(0) && @settings['tracksToRip'][0] == 1
			@settings['tracksToRip'].unshift(0)
		end

 		if @settings['req_matches_all'] > @settings['req_matches_errors'] ; @settings['req_matches_errors'] = @settings['req_matches_all'] end
		return true
	end

	def checkOtherSettings
		copyString = ""
		lastChar = ""

		#first remove all double quotes. then iterate over each char
		@settings['othersettings'].delete('"').split(//).each do |char|
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

		@settings['othersettings'] = copyString

		puts @settings['othersettings'] if @settings['debug']
	end

	def testDeps
		{"ripper" => "cdparanoia", "flac" => "flac", "vorbis" => "oggenc", "mp3" => "lame"}.each do |setting, binary|
			if @settings[setting] && !installed(binary)
				@error = ["error", _("%s not found on your system!") % [binary.capitalize]]
				return false
			end
		end
		return true
	end

	# check for some non-blocking problems
	def getWarnings
		if @settings['normalize'] == 'normalize' && !installed('normalize')
			@warnings << _("WARNING: Normalize is not installed!\n")
		end

		if @settings['normalize'] == 'replaygain'
			if @settings['flac'] && !installed('metaflac')
				@warnings << _("WARNING: Replaygain for flac (metaflac) not installed!\n")
			end

			if @settings['vorbis'] && !installed('vorbisgain')
				@warnings << _("WARNING: Replaygain for vorbis (vorbisgain) not installed!\n")
			end

			if @settings['mp3'] && !installed('mp3gain')
				@warnings << _("WARNING: Replaygain for mp3 (mp3gain) not installed!\n")
			end

			if @settings['wav'] && !installed('wavegain')
				@warnings << _("WARNING: Replaygain for wav (wavegain) not installed!\n")
			end
		end
	end

	def summary
		return @settings['log'].short_summary
	end

	def postfixDir
		@settings['Out'].postfixDir()
	end

	def overwriteDir
		@settings['Out'].overwriteDir()
	end

	def updateGui
		@settings['log'].add(_("Cdrom player used to rip:\n%s\n") % [@settings['cd'].devicename])
		@settings['log'].add(_("Cdrom offset used: %s\n\n") % [@settings['offset']])
		@settings['log'].add(_("Ripper used: cdparanoia %s\n") % [if @settings['rippersettings'] ; @settings['rippersettings'] else _('default settings') end])
		@settings['log'].add(_("Matches required for all chunks: %s\n") % [@settings['req_matches_all']])
		@settings['log'].add(_("Matches required for erroneous chunks: %s\n\n") % [@settings['req_matches_errors']])

		@warnings.each{|warning| @settings['log'].add(warning)}
		@settings['log'].add(_("Codec(s) used:\n"))
		if @settings['flac']; @settings['log'].add(_("-flac \t-> %s (%s)\n") % [@settings['flacsettings'], `flac --version`.strip]) end
		if @settings['vorbis']; @settings['log'].add(_("-vorbis\t-> %s (%s)\n") % [@settings['vorbissettings'], `oggenc --version`.strip]) end
		if @settings['mp3']; @settings['log'].add(_("-mp3\t-> %s\n(%s\n") % [@settings['mp3settings'], `lame --version`.split("\n")[0]]) end
		if @settings['wav']; @settings['log'].add(_("-wav\n")) end
		if @settings['other'] ; @settings['log'].add(_("-other\t-> %s\n") % [@settings['othersettings']]) end
		@settings['log'].add(_("\nCDDB INFO\n"))
		@settings['log'].add(_("\nArtist\t= "))
		@settings['log'].add(@settings['cd'].md.artist)
		@settings['log'].add(_("\nAlbum\t= "))
		@settings['log'].add(@settings['cd'].md.album)
		@settings['log'].add(_("\nYear\t= ") + @settings['cd'].md.year)
		@settings['log'].add(_("\nGenre\t= ") + @settings['cd'].md.genre)
		@settings['log'].add(_("\nTracks\t= ") + @settings['cd'].audiotracks.to_s +
		" (#{@settings['tracksToRip'].length} " + _("selected") + ")\n\n")
		@settings['cd'].audiotracks.times do |track|
			if @settings['tracksToRip'] == 'image' || @settings['tracksToRip'].include?(track + 1)
				@settings['log'].add("#{sprintf("%02d", track + 1)} - #{@settings['cd'].md.tracklist[track]}\n")
			end
		end
	end

	def computePercentage
		@settings['percentages'] = Hash.new() #progress for each track
		totalSectors = 0.0 # It can be that the user doesn't want to rip all tracks, so calculate it
		@settings['tracksToRip'].each{|track| totalSectors += @settings['cd'].getLengthSector(track)} #update totalSectors
		@settings['tracksToRip'].each{|track| @settings['percentages'][track] = @settings['cd'].getLengthSector(track) / totalSectors}
	end
end
