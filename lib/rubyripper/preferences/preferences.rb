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


# The settings class is responsible for:
# * Managing the location of the settings file
# * Loading the settings
# * Saving the settings
# * Finding the default help programs like browser, editor, etcetera
class Preferences

	# * loadPrefs = instance of LoadPrefs
	# * savePrefs = instance of SavePrefs
	# * filePrefs = instance of FilePrefs
	# * dependency = instance of Dependency
	def initialize(loadPrefs, savePrefs, filePrefs, dependency)
		@load = loadPrefs
		@save = savePrefs
		@file = filePrefs
		@deps = dependency
		checkArguments()

		@settings = Hash.new()
		@configFound = false
	end

	# load the actual configfile
	def loadConfigFile(configFileInput = false)
		@configFileInput = configFileInput

		setDefaultSettings()
		@configFile = @file.config(configFileInput)
		settings = @load.get(@configFile)
				
		loadSettings()
	end

	# return the settings hash
	def getSettings ; return @settings ; end

	# return if the specified configfile is found
	def isConfigFound ; return @configFound ; end

	# save the updated settings
	# * config = hash with updated settings
	# * test = true when used while unit testing (prevents writing to files)
	def save(config) ; setSettings(config) ; end

private

	# check the arguments
	def checkArguments
		unless (@configFileInput == false || @configFileInput.class == String)
			raise ArgumentError, "ConfigfileInput parameter must be false or a string"
		end

		unless @deps.class == Dependency
			raise ArgumentError, "deps parameter must be of Dependency class"
		end
	end

	# setup the the default settings
	def setDefaultSettings
		@defaultSettings = {"flac" => false,
			"settingsFlac" => "--best -V", #passed to flac
			"vorbis" => true, 
			"settingsVorbis" => "-q 4", #passed to vorbis
			"mp3" => false,
			"settingsMp3" => "-V 3 --id3v2-only", #passed to lame
			"wav" => false, 
			"other" => false, #any other codec
			"settingsOther" => '', #the complete command
			"playlist" => true,
			"cdrom" => cdrom_drive(),
			"offset" => 0,
			"maxThreads" => 2, #number of encoding proces while ripping
			"rippersettings" => '', #passed to cdparanoia
			"maxTries" => 5, #number of tries before giving up correcting
			'basedir' => '~/', #where to store your new rips?
			'namingNormal' => '%f/%a (%y) %b/%n - %t', # normal discs
			'namingVarious' => '%f/%va (%y) %b/%n - %a - %t', # various artist discs
			'namingImage' => '%f/%a (%y) %b/%a - %b (%y)', # image rips
			"verbose" => false, # extra info shown in terminal
			"debug" => true, # extra debug info shown in terminal
			"eject" => true, # open up the tray when finished?
			'ripHiddenAudio' => true, # rip part before track 1?
			'minLengthHiddenTrack' => 2, #minimum seconds hidden track
			"reqMatchesErrors" => 2, # # required matches when errors detected
			"reqMatchesAll" => 2,  # required matches when no errors detected
			"site" => "http://freedb.freedb.org/~cddb/cddb.cgi", # freedb site
			"username" => "anonymous", # user name freedb
			"hostname" => "my_secret.com", # hostname freedb
			"firstHit" => true, # always choose 1st option
			"freedb" => true, # enable freedb
			"editor" => @deps.get('editor'), #default editor
			"filemanager" => @deps.get('filemanager'), #default file manager
			"browser" => @deps.get('browser'), #default browser
			"noLog" => false, #delete log if no errors?
			"createCue" => true, #create cuesheet
			"image" => false, #save to single file
			'normalizer' => 'none', #normalize volume?
			'gain' => "album", #gain mode
			'gainTagsOnly' => false, #not actually modify audio
			'noSpaces' => false, #replace spaces with underscores
			'noCapitals' => false, #replace uppercase with lowercase
			'preGaps' => "prepend", #way to handle pregaps
			'preEmphasis' => 'cue' #way to handle pre-emphasis
		}
	end

				# only load a setting that is included in the default
				if @defaultSettings.key?(key)
					@settings[key] = value
				else
					puts "WARNING: invalid setting: #{key}"
				end

			# check if settings are missing
			@defaultSettings.each do |key, value|
				if not @settings.has_key?(key)
					@settings[key] = value
					puts "WARNING: setting #{key} was missing in config file!"
				end
			end

	# update the settings to the config file
	# * settings = hash with updated settings
	# * test = if true don't write changes to the settings file
	def setSettings(settings)
		unless (settings.class == Hash)
			raise ArgumentError, "Settings parameter must be a Hash."
		end

		# update the settings
		@settings.each do |key, value|
			if settings.has_key?(key)
				@settings[key] = settings[key]
			end
		end
	end
end

