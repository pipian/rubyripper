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

require 'rubyripper/system/dependency'

# This class manages the executing of external commands
# A seperate class allows unified checking of exit status
# Also it allows for better unit testing, since it is easily mocked
class Execute
attr_reader :status

  # * deps = instance of Dependency
  def initialize(command, dependency = Dependency.new)
    @command = command
    @deps = dependency
  end

  def eject(cdrom)
    Thread.new do
      if @deps.installed?('eject')
        launch("eject #{cdrom}")
      elsif @deps.installed?('diskutil')
        launch("diskutil eject #{cdrom}") #Mac users have diskutil instead of eject
      else
        puts _("No eject utility found!")
      end
    end
  end

  # return a temporary filename
  def getTempFile(name)
    require 'tmpdir'
    File.join(Dir.tmpdir, name)
  end

  # return output for command
  # clear the file if it exists before the program runs
  def launch(command, filename=false, noTranslations=nil)
    output = nil
    program = command.split[0]
    command = "LANG=C; #{command}" if noTranslations

    if @deps.installed?(program)
      File.delete(filename) if filename && File.exist?(filename)
      output = `sh -c #{command}`
      @status = 'ok' if $?.success?
      @filename = filename
    end

    return output
  end

  # return created file with command
  def readFile
    return File.read(@filename) if File.exists?(@filename)
  end
end
