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

require 'singleton'
require 'fileutils'

# This class will help with the file and directory operations of Ruby
class FileAndDir
  include Singleton unless $run_specs

  def mkdir(dir)
    Dir.mkdir(dir)
  end

  def exists?(filename)
    if File.exists?(file = File.expand_path(filename))
      return file
    else		  
      return false
    end
  end

  def file?(file)
    return File.file?(file)
  end
  
  def directory?(dir)
    return File.directory?(dir)
  end

  def glob(query)
    return Dir.glob(query)
  end

  # remove the thing, no matter if file or directory
  def remove(item)
    if File.exists?(item)
      if File.file?(item)
        File.delete(item)
      elsif File.directory?(item)
        if Dir.entries(item) == 2
          Dir.delete(item)
        end
      end
    end
  end

  # create any directories that are needed for the filename
  def createDirs(filename)
    dirs = Array.new
    
    # find all directories that do not exist yet
    # first entry will be the dirname, than it's parent and so on
    while (!File.directory?(dir = File.dirname(filename)))
      dirs << dir
      filename = dir
    end

    # now create the dirs, starting with the main parent
    while !dirs.empty?
      Dir.mkdir(dirs.pop())
    end
  end
  
  # check if the existing root dir is writable, so subdirs can be created
  def writable?(dir)
    until(File.exist?(dir) && File.directory?(dir))
      dir = File.dirname(dir)
    end
    File.writable?(dir)
  end

  # * filename = Name of the existing file
  def read(filename, encoding='r')
    if !File.file?(filename)
      return String.new
    else
      content = String.new
      File.open(filename, encoding) do |file|
        content = file.read()
      end
      return content
    end
  end

  # filename = Name of the new file
  # content = A string with the content of the new file
  # force = overwrite if file exists
  def write(filename, content, update = true)
    status = false
    if !update && File.file?(filename)
      status = 'fileExists'
    else
      createDirs(filename) unless File.exists?(File.dirname(filename))
      writeContent(filename, content)
      status = 'ok'
    end
    return status
  end

  private

  def writeContent(filename, content)
    File.open(filename, 'w') do |file|
      file.write(content)
    end
  end
end
