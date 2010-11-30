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
class Settings

	# * deps = instance of Dependency class
	# * configFileInput = the location of a custom configFile
	def initialize(deps, configFileInput = false)
		@configFileInput = configFileInput
		@deps = deps
		checkArguments()

		@settings = Hash.new()
		@configFound = false
		setDefaultSettings()
		findConfigFile()
		findOtherFiles()
		migrationCheck()
		loadSettings()
	end

	# return the settings hash
	def getSettings ; return @settings ; end

	# return if the specified configfile is found
	def isConfigFound ; return @configFound ; end

	# save the updated settings
	# * config = hash with updated settings
	# * test = true when used while unit testing (prevents writing to files)
	def save(config, test=false) ; setSettings(config, test) ; end

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
			"editor" => @deps.getHelpApp('editor'), #default editor
			"filemanager" => @deps.getHelpApp('filemanager'), #default file manager
			"browser" => @deps.getHelpApp('browser'), #default browser
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

	# find the location of the config file
	def findConfigFile
		if @configFileInput != false
			@configFile = File.expand_path(@configFileInput)		
			@configFound = true if File.exists?(@configFile)		
		else
			dir = ENV['XDG_CONFIG_HOME'] || File.join(ENV['HOME'], '.config')
			@configFile = File.join(dir, 'rubyripper/settings')
			createDirs(File.dirname(@configFile))
		end
	end

	# find the location fo the other files
	def findOtherFiles
		dir = ENV['XDG_CACHE_HOME'] || File.join(ENV['HOME'], '.cache')
		@cacheFile = File.join(dir, 'rubyripper/freedb.yaml')
		createDirs(File.dirname(@cacheFile))

		#store the location in the settings for use later on
		@defaultSettings['freedbCache'] = @cacheFile
	end

	# help function to create dirs
	def createDirs(dirName)
		if !File.directory?(File.dirname(dirName))
			createDirs(File.dirname(dirName))
		end
	
		if !File.directory?(dirName)
			Dir.mkdir(dirName)
		end
	end

	# check for existing configs in old directories and move them
	# to the standard directories conform the freedesktop.org spec
	def migrationCheck()
		oldDir = File.join(ENV['HOME'], '.rubyripper')
		if File.directory?(oldDir)
			puts "Auto migrating to new file locations..."
			oldConfig = File.join(ENV['HOME'], '.rubyripper/settings')
			oldCache = File.join(ENV['HOME'], '.rubyripper/freedb.yaml')
			moveFiles(oldConfig, oldCache)
			deleteOldDir(oldDir)
		end

		# clean up a very old config file
		if File.exists?(oldFile = File.join(ENV['HOME'], '.rubyripper_settings'))
			FileUtils.rm(oldFile)
		end
	end

	# help function to move the files
	def moveFiles(oldConfig, oldCache)
		if File.exists?(oldConfig)
			FileUtils.mv(oldConfig, @configFile)
			puts "New location of config file: #{@configFile}"
		end

		if File.exists?(oldCache)
			FileUtils.mv(oldCache, @cacheFile)
			puts "New location of freedb file: #{@cacheFile}"
		end
	end

	# help function to remove the old dir
	def deleteOldDir(oldDir)
		if File.symlink?(oldDir)
			File.delete(oldDir)
		elsif Dir.entries(oldDir).size > 2 # some leftover file(s) remain
			puts "#{oldDir} could not be removed: it's not empty!"
		else
			Dir.delete(oldDir)
		end
		puts "Auto migration finished succesfull."
	end
	
	# update the settings to the config file
	# * settings = hash with updated settings
	# * test = if true don't write changes to the settings file
	def setSettings(settings, test=false)
		unless (settings.class == Hash)
			raise ArgumentError, "Settings parameter must be a Hash."
		end

		# update the settings
		@settings.each do |key, value|
			if settings.has_key?(key)
				@settings[key] = settings[key]
			end
		end

		# update the config file, but do not update when unit testing
		if test == false
			file = File.new(@configFile, 'w')
			@settings.each do |key, value|
				file.puts "#{key}=#{value}"
			end
			file.close()
		end
	end

	# first the values found in the config file, then add any missing values
	def loadSettings()
		if File.exist?(@configFile)
			file = File.new(@configFile,'r')
			while line = file.gets
				key, value = line.split('=', 2)
				# remove the trailing newline character
				value.rstrip!
				# replace the strings false/true with a bool
				if value == "false" ; value = false 
				elsif value == "true" ; value = true
				# replace two quotes with an empty string
				elsif value == "''" ; value = ''
				# replace an integer string with an integer 
				elsif value.to_i > 0 || value == '0' ; value = value.to_i
				end
				# only load a setting that is included in the default
				if @defaultSettings.key?(key)
					@settings[key] = value
				else
					puts "WARNING: invalid setting: #{key}"
				end
			end
			file.close()
			
			# check if settings are missing
			@defaultSettings.each do |key, value|
				if not @settings.has_key?(key)
					@settings[key] = value
					puts "WARNING: setting #{key} was missing in config file!"
				end
			end		
		else
			@settings = @defaultSettings.dup		
		end
	end

	# determine default drive
	def cdrom_drive #default values for cdrom drives under differenty os'es
		drive = 'Unknown!'
		system = RUBY_PLATFORM
		if system.include?('openbsd')
			drive = '/dev/cd0c' # as provided in issue 324
		elsif system.include?('linux') || system.include?('bsd')
			drive = '/dev/cdrom'
		elsif system.include?('darwin')
			drive = '/dev/disk1'
		end
		return drive
	end
end

