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

# This class manages the executing of external commands
# A seperate class allows unified checking of exit status
# Also it allows for better unit testing, since it is easily mocked
class FireCommand

	# * deps = instance of Dependency
	def initialize(dependency)
		@deps = dependency
		@status = ''
		@filename = ''
	end

	# return output for command
	def launch(program, command, filename=false)
		output = false

		if @deps.get(program)
			@filename = filename
			if @filename != false
				File.delete(@filename) if File.exist?(@filename)
			end

			output = `#{command}`
			@status = $?.success?
		end

		return output
	end

	# return exit status for command
	def status
		return @status
	end

	# return created file with command
	def file
		return File.read(@filename) if File.exists?(@filename)
	end
end
