#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012  Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/system/dependency'
require 'rubyripper/errors'
require 'pty'

# This class manages the executing of external commands
# A seperate class allows unified checking of exit status
# Also it allows for better unit testing, since it is easily mocked
class Execute
attr_reader :status

  def initialize(deps=nil, prefs=nil)
    @deps = deps ? deps : Dependency.instance
    @prefs = prefs ? prefs : Preferences::Main.instance
  end

  # return a temporary filename
  def getTempFile(name)
    require 'tmpdir'
    File.join(Dir.tmpdir, name)
  end

  # return output for command
  # clear the file if it exists before the program runs
  def launch(command, filename=false, noTranslations=nil)
    return true if command.empty?
    program = command.split[0]
    command = "LC_ALL=C; #{command}" if noTranslations
    puts "DEBUG: #{command}" if @prefs.debug

    if @deps.installed?(program)
      File.delete(filename) if filename && File.exist?(filename)
      begin
        output = Array.new
        PTY.spawn(command) do |stdin, stdout, pid|
          begin
            stdin.each { |line| output << line }
          rescue Errno::EIO
            # normal end of input stream
          rescue Exception => exception
            puts "DEBUG: Command #{command} failed with exception: #{exception.message}" if @prefs.debug
          end
        end
      rescue
        puts Errors.failedToExecute(program, command)
        output = ''
      end
      @filename = filename
    else
      puts Errors.binaryNotFound(program)
    end

    return output
  end
  
  # return created file with command
  def readFile
    return File.read(@filename) if File.exists?(@filename)
  end
end
