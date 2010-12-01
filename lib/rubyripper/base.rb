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

# The current version of Rubyripper
$rr_version = '0.6.1a'

# Crash on errors, because bugs are otherwise hard to find
Thread.abort_on_exception = true

# Make sure the locale files work before installing
ENV['GETTEXT_PATH'] = File.join($localdir, '/data/locale')

# Set translation functions, $" contains all loaded libs in an array
if $".join().include?('gettext.rb')
	include GetText
	bindtextdomain("rubyripper")
else
	def _(txt)
		return txt
	end
end

# A separate help function to make it faster
def getExampleFilenameNormal(basedir, layout)
	filename = File.expand_path(File.join(basedir, layout))
	filename = _("Example filename: %s.ext") % [filename]
	{'%a' => 'Judas Priest', '%b' => 'Sin After Sin', '%f' => 'codec', 
	'%g' => 'Rock', '%y' => '1977', '%n' =>'01', '%t' => 'Sinner', 
	'%i' =>'inputfile', '%o' => 'outputfile'}.each do |key, value| 
		filename.gsub!(key,value)
	end
	return filename
end

# A separate help function to make it faster
def getExampleFilenameVarious(basedir, layout)
	filename = File.expand_path(File.join(basedir, layout))
	filename = _("Example filename: %s.ext") % [filename]
	{'%va' => 'Various Artists', '%b' => 'TMF Rockzone', '%f' => 'codec',
	'%g' => "Rock", '%y' => '1999', '%n' => '01', '%a' => 'Kid Rock', 
	'%t' => 'Cowboy'}.each do |key, value|
		filename.gsub!(key,value)
	end
	return filename
end

# A help function to eject the disc drive
def eject(cdrom)
	Thread.new do
	 	if installed('eject') ; `eject #{cdrom}`
		#Mac users don't got eject, but diskutil
		elsif installed('diskutil'); `diskutil eject #{cdrom}`
		else puts _("No eject utility found!")
		end
	end
end
