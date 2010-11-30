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

# Tracklist class is responsible for showing and editing the metadata
class CliTracklist
attr_reader :getTracks

	def initialize(settings, status)
		@settings = settings
		if @settings['image']
			@tracksToRip = ['image']
		else
			@tracksToRip = (1..@settings['cd'].audiotracks).to_a
			if status != "default"
				chooseTracks()
			end
		end
	end

	# Return the tracks to be ripped
	def getTracks
		return @tracksToRip
	end

	# Want all tracks?
	def allTracks
		if getAnswer(_("\nShould all tracks be ripped ? (y/n) "), "yes", _('y'))
			puts _("Tracks to rip are %s") % [@tracksToRip.join(" ")]
		else
			chooseTracks()
		end
	end

	# Make a choice which tracks are needed
	def chooseTracks
		succes = false
		while !succes
			puts _("Current selection of tracks : %s") % [@tracksToRip.join(' ')]
			number = getAnswer(_("Enter 1 for entering the tracknumbers you want to remove.\nEnter 2 for entering the tracks you want to keep.\nYour choice: "), "number", 1)
			if number == 1
				print _("Type the numbers of the tracks you want to remove and separate them with a space: ")
				answer = STDIN.gets.strip.split
				answer.each_index{|index| answer[index] = answer[index].to_i} #convert to integers
				@tracksToRip -= answer # don't you just love ruby math? [1,2,3,4,5] - [3,4] = [1,2,5]
			elsif number == 2
				print _("Type the numbers of the tracks you want to keep and separate them with a space: ")
				answer = STDIN.gets.strip.split
				answer.each_index{|index| answer[index] = answer[index].to_i} #convert to integers
				remove = @tracksToRip - answer # remove is inverted result -> which tracks you want to remove?
				@tracksToRip -= remove # remove these
			else
				puts _("%s is not a valid number! Please enter 1 or 2!\n") % [number]
			end
			if number == 1 || number == 2
				puts _("Current selection of tracks : %s") % [@tracksToRip.join(' ')]
				succes = !getAnswer(_("Do you want to make any changes? (y/n) : "), "yes", _("n"))
			end
		end
	end
end
