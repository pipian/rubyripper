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

  # create dir + parent directories if needed
  def createDir(dir)
    dir = File.expand_path(dir)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
  end
  
  # autodetection if it is a file or directory fails when directory contains a dot
  def createDirForFile(file)
    createDir(File.dirname(file))
  end

  # remove dir + subdirectories if needed
  def removeDir(dir)
    dir = File.expand_path(dir)
    FileUtils.rm_rf(dir) if File.exist?(dir)
  end
  
  # remove the thing, no matter if file or directory
  def remove(item)
    item = File.expand_path(item)
    FileUtils.rm_rf(item) if File.exist?(item)
  end

  # get the extension of the file
  def extension(file)
    File.extname(file)
  end
  
  # query for file
  def glob(pattern)
    Dir.glob(pattern)
  end
  
  def exists?(filename)
    if File.exists?(file = File.expand_path(filename))
      return file
    else		  
      return false
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
      createDirForFile(filename)
      writeContent(filename, content)
      status = 'ok'
    end
    return status
  end

  private
  
  # if the method is not found try to look it up in the File object
  def method_missing(name, *args)
    File.send(name, *args)
  end

  def writeContent(filename, content)
    File.open(filename, 'w') do |file|
      file.write(content)
    end
  end
end
