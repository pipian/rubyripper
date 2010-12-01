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

# This class tests the dependency class
class TC_Dependency < Test::Unit::TestCase

	# test is inst001 passes
	def test_DependencyKeys
		inst001 = Dependency.new()
		keysDep = ['cdparanoia', 'ruby-gtk2', 'ruby-gettext', 'discid', 
'cd-discid', 'eject', 'flac', 'vorbis', 'lame', 'wavegain', 'vorbisgain',
'mp3gain', 'normalize', 'cdrdao', 'cd-info', 'ls', 'diskutil']
		keysHelpApp = ['filemanager', 'editor', 'browser']
		
		keysDep.each do |key|
			assert_kind_of(Boolean, inst001.getDep(key), "#{key} must be boolean")
		end

		keysHelpApp.each do |key|
			assert_kind_of(String, inst001.getHelpApp(key), "#{key} must be string")
			assert(inst001.getHelpApp(key).length > 0, "#{key} may not be empty")
		end
	end
end
