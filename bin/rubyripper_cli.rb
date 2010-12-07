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

# set the directory of the local installation
$localdir = File.expand_path(File.dirname(File.dirname(__FILE__)))

# Put the local lib directory on top of the ruby default lib search path
$:.insert(0, File.join($localdir, '../lib'))

# Try to find the rubyripper lib files
begin
	require 'rubyripper/base.rb'
rescue LoadError
	puts 'The rubyripper lib files can\'t be found!'
	puts 'Perhaps you need to add the directory to the RUBYLIB variable?'
	exit()
end

require 'rubyripper/dependency.rb'
require 'rubyripper/cli/cliSettings.rb'
require 'rubyripper/cli/cliMetadata.rb'
require 'rubyripper/cli/cliGetAnswer.rb'
# TODO require 'rubyripper/cli/cliTracklist.rb'

# The class that initiates the commandline interface
class CommandLineInterface
	
	# start up the interface
	def initialize()
		@rippingLog = ""
		@rippingProgress = 0.0
		@encodingProgress = 0.0
		@objects = Hash.new
		setObjects()
	end

	def setObjects
		# verify if all dependencies are found
		@objects['deps'] = Dependency.new(verbose=true, runtime=true)
	
		# save all answer machines in a Hash and pass them (better for testing)
		@objects['getString'] = GetString.new
		@objects['getInt'] = GetInt.new
		@objects['getBool'] = GetBool.new

		# set the gui
		@objects['gui'] = self

		# get the settings
		@objects['settingsCli'] = CliSettings.new(@objects)
		@objects['disc'] = Disc.new(@objects)

		# show the discinfo
		@objects['discCli'] = CliMetadata.new(@objects)

		#getDiscInfo()
		#selectTracks()
	end

	# The only function where the lib files are reporting to
	def update(modus, value=false)
		if modus == "ripping_progress"
			progress = "%.3g" % (value * 100)
			puts "Ripping progress (#{progress} %)"
		elsif modus == "encoding_progress"
			progress = "%.3g" % (value * 100)
			puts "Encoding progress (#{progress} %)"
		elsif modus == "log_change"
			print value
		elsif modus == "error"
			print value
			print "\n"
			if get_answer(_("Do you want to change your settings? (y/n) : "), "yes",_("y"))
				@settingsInfo.editSettings()
			end
		elsif modus == "dir_exists"
			dirExists()
		end
	end

private

	# Show the disc info and include error handling
	def getDiscInfo()
		if @discCli.getError
			puts @discCli.getError
			if getAnswer(_("Do you want to change your settings? "), "yes", _('y'))
				@settingsCli.editSettings()
				getDiscInfo()
			end
			exit()
		end
	end

	# cancel the rip
	def cancelRip()
		puts _("Rip is canceled, exiting...")
		eject(@settings['cd'].cdrom)
		exit()
	end

	# get the tracks, verify the settings
	def prepareRip()
		@settings['tracksToRip'] = CliTracklist.new(@settings, @discInfo.getStatus)
		
		# starts some check if the settings are sane		
		@rubyripper = Rubyripper.new(@settings, self)
		
		status = @rubyripper.settingsOk
		if status == true
			@rubyripper.startRip()
		else
			update(status[0], status[1])
		end
	end
	
	# A dialog in case the output directory exists
	def dirExists
		puts _("The output directory already exists. What would you like to do?")
		puts ""
		puts _("1) Auto rename the output directory")
		puts _("2) Overwrite the existing directory")
		puts _("3) Cancel the rip and eject the disc")
		puts ""

		answer = get_answer(_("Please enter the number of your choice: "), "number", 1)
		if answer == 1; @rubyripper.postfixDir() ; @rubyripper.startRip()
		elsif answer == 2; @rubyripper.overwriteDir() ; @rubyripper.startRip()
		else cancelRip()
		end
	end
end	

if __FILE__ == $0
	CommandLineInterface.new()
end

