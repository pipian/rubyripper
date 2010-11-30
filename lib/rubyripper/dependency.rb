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

# The Dependency class is responsible for all dependency checking
class Dependency
	
	# * verbose = print extra info to the terminal?
	# * runtime = if forced dependency not found, exit? 
	def initialize(verbose = false, runtime = false)
		@verbose = verbose
		@runtime = runtime

		checkArguments()
		setConsequence()

		checkForcedDeps()
		checkOptionalDeps()
		@deps = arrayToHash(@forcedDeps + @optionalDeps)

		checkHelpApps()
	
		showInfo() if verbose == true
		forceDepsRuntime() if runtime == true
	end

	# return true if the Program is found: getDep('Cdparanoia')
	def getDep(key) ; return @deps[key] ; end

	# return a string with the application: getHelpApp('Browser')
	def getHelpApp(key) ; return @helpApps[key] ; end

private
	# check the arguments
	def checkArguments
		unless (@verbose == true || @verbose == false)
			raise ArgumentError, "Verbose parameter must be a boolean"
		end

		unless (@runtime == true || @runtime == false)
			raise ArgumentError, "Runtime parameter must be a boolean"
		end
	end

	# A help function to check if an application is isInstalled
	def isInstalled(filename)
		ENV['PATH'].split(':').each do |dir|
			if File.exist?(File.join(dir, filename)) ; return true end
		end
		# It can also be in current working dir
		if File.exist?(filename) ; return true else return false end
	end

	# fill the Hash with consequences
	def setConsequence
		@consequence = {
			'cdparanoia' => _("Rubyripper can't be used without cdparanoia!"),
			'ruby-gtk2' => _("You won't be able to use the gtk2 interface."),
			'ruby-gettext' => _("You won't be able to use translations."),
			'discid' => _("You won't have accurate freedb string \
calculation unless %s is installed.") % ['Cd-discid'],
			'cd-discid' => _("You won't have accurate freedb string \
calculation unless %s is installed.") % ['Discid'],
			'eject' => _("Your disc tray can not be opened after ripping"),
			'flac' => _("You won't be able to encode in flac."),
			'vorbis' => _("You won't be able to encode in vorbis."),
			'lame' => _("You won't be able to encode in lame MP3."),
			'wavegain' => _("You won't be able to replaygain wav files."),
			'vorbisgain' => _("You won't be able to replaygain vorbis files."),
			'mp3gain' => _("You won't be able to replaygain Lame mp3 files."),
			'normalize' => _("You won't be able to normalize audio files."),
			'cdrdao' => _("You won't be able to make cuesheets"),
			'cd-info' => _("Cd-info helps to detect data tracks."),
			'ls' => _("Show rights in case of problems")
		}
	end



	# convert the arrays to hashes (they were array's to prevent random sorting)
	def arrayToHash(array)
		returnHash = Hash.new
		array.each{|k,v| returnHash[k]=v}
		return returnHash
	end
	
	# check if all the forced dependencies are there	
	def checkForcedDeps()
		@forcedDeps = Array.new
		@forcedDeps << ['cdparanoia', isInstalled('cdparanoia')]
	end

	# check if all the optional dependencies are there
	def checkOptionalDeps()
		@optionalDeps = Array.new
		@optionalDeps << ['ruby-gtk2', isGtk2Found()]
		@optionalDeps << ['ruby-gettext', isGettextFound()]
		@optionalDeps << ['discid', isInstalled('discid')]
		@optionalDeps << ['cd-discid', isInstalled('cd-discid')]
		@optionalDeps << ['eject', isInstalled('eject') || isInstalled('diskutil')]

		# codecs
		@optionalDeps << ['flac', isInstalled('flac')]
		@optionalDeps << ['vorbis', isInstalled('oggenc')]
		@optionalDeps << ['lame', isInstalled('lame')]
		
		# replaygain / normalize
		@optionalDeps << ['wavegain', isInstalled('wavegain')]
		@optionalDeps << ['vorbisgain', isInstalled('vorbisgain')]
		@optionalDeps << ['mp3gain', isInstalled('mp3gain')]
		@optionalDeps << ['normalize', isInstalled('normalize')]

		# extra apps
		@optionalDeps << ['cdrdao', isInstalled('cdrdao')]		
		@optionalDeps << ['cd-info', isInstalled('cd-info')]
		@optionalDeps << ['ls', isInstalled('ls')]
		@optionalDeps << ['diskutil', isInstalled('diskutil')]
	end

	# check for ruby-gtk2
	def isGtk2Found
		begin
			require 'gtk2'
			return true
		rescue LoadError
			return false
		end
	end

	# check for ruby-gettext
	def isGettextFound
		begin
			require 'gettext'
			return true
		rescue LoadError
			return false
		end
	end

	# show the results in a terminal
	def showInfo
		print _("\n\nCHECKING FORCED DEPENDENCIES\n\n")
		printResults(@forcedDeps)
		print _("\nCHECKING OPTIONAL DEPENDENCIES\n\n")
		printResults(@optionalDeps)
		print "\n\n"
	end

	# iterate over the deps and show the detailInfo
	def printResults(deps)
		deps.each do |key, value|
			if value == true
				puts "#{key}: [OK]"
			else
				puts "#{key}: [NOT OK]"
				puts @consequence[key] if @consequence.key?(key)
			end
		end
	end

	# when running rubyripper make sure the forced deps are there
	def forceDepsRuntime
		if not @deps['cdparanoia']
			puts "Cdparanoia not found on your system."
			puts "This is required to run rubyripper. Exiting..."
			exit()
		end
	end
	
	# find the default local apps for opening files, html, etc.
	def checkHelpApps
		@helpApps = Hash.new
		@helpApps['filemanager'] = filemanager()
		@helpApps['editor'] = editor()
		@helpApps['browser'] = browser()
	end

	# determine default file manager
	def filemanager
		if ENV['DESKTOP_SESSION'] == 'kde' && isInstalled('dolphin')
			return 'dolphin'
		elsif ENV['DESKTOP_SESSION'] == 'kde' && isInstalled('konqueror')
			return 'konqueror'
		elsif isInstalled('thunar')
			return 'thunar' #Xfce4 filemanager
		elsif isInstalled('nautilus')
			return 'nautilus --no-desktop' #Gnome filemanager
		else
			return 'echo'
		end
	end

	# determine default editor
	def editor # look for default editor
		if ENV['DESKTOP_SESSION'] == 'kde' && isInstalled('kwrite')
			return 'kwrite'
		elsif isInstalled('mousepad')
			return 'mousepad' #Xfce4 editor
		elsif isInstalled('gedit')
			return 'gedit' #Gnome editor
		elsif ENV.key?('EDITOR')
			return ENV['EDITOR']
		else	
			return 'echo'
		end
	end

	# determine default browser
	def browser
		if isInstalled('chromium')
			return 'chromium'
		elsif ENV['DESKTOP_SESSION'] == 'kde' && isInstalled('konqueror')
			return 'konqueror'
		elsif isInstalled('epiphany')
			return 'epiphany'
		elsif isInstalled('firefox')
			return 'firefox'
		elsif isInstalled('opera')
			return 'opera'
		elsif ENV.key?('BROWSER')
			return ENV['BROWSER']
		else
			return 'echo'
		end
	end
end
