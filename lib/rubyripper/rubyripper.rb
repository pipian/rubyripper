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
attr_reader :outputDir, :outputFile, :log

  # * preferences = The preferences object
  # * userInterface = the user interface object (with the update function)
  # * disc = the disc object
  # * trackSelection = an array with selected tracks
  def initialize(preferences, userInterface, disc, trackSelection)
    @prefs = preferences
    @ui = userInterface
    @disc = disc
    @trackSelection = trackSelection
  end

  # check if all is ready to go
  def checkConfiguration
    require 'rubyripper/checkConfigBeforeRipping'
    return CheckConfigBeforeRipping.new(@prefs, @ui, @disc, @trackSelection).result
  end

  # do some neccesary preparation and start the ripping
  def startRip
    autofixCommonMistakes()
    createHelpObjects()
    @outputFile.start() # TODO find a better name for the class and function
    @log.start() # TODO find a better name for the class and function
    @rippingInfoAtStart.show()

    # @disc.md.saveChanges() # TODO ??
    # @outputDir = @prefs['Out'].getDir() # TODO ask if directory is available
    #waitForToc() # TODO ??

		computePercentage() # Do some pre-work to get the progress updater working later on
		require 'digest/md5' # Needed for secure class, only have to load them ones here.
		@encoding = Encode.new(@prefs) #Create an instance for encoding
		@ripping = SecureRip.new(@prefs, @encoding) #create an instance for ripping
	end

  def createHelpObjects
    require 'rubyripper/outputFile'
    @outputFile = OutputFile.new(@prefs, @disc)

    require 'rubyripper/log'
    @log = Log.new(@prefs, @disc, @outputFile, @ui)

    require 'rubyripper/rippingInfoAtStart'
    @rippingInfoAtStart = RippingInfoAtStart.new(@prefs, @disc, @log, @trackSelection)
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

	def computePercentage
		@prefs['percentages'] = Hash.new() #progress for each track
		totalSectors = 0.0 # It can be that the user doesn't want to rip all tracks, so calculate it
		@prefs['tracksToRip'].each{|track| totalSectors += @prefs['cd'].getLengthSector(track)} #update totalSectors
		@prefs['tracksToRip'].each{|track| @prefs['percentages'][track] = @prefs['cd'].getLengthSector(track) / totalSectors}
	end
end
