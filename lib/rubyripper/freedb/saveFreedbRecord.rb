#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/system/fileAndDir'

# class helping to store the retrieved freedb record
# do this conform standards at location $HOME/.cddb/<category>/<discid>
class SaveFreedbRecord
  def initialize(fileAndDir=nil)
    @file = fileAndDir ? fileAndDir : FileAndDir.instance()
  end

  # * freedbRecord = the complete freedb record string with all metadata
  # * category = the freedb category string, needed for saving locally
  # * discid = the discid string, which is the filename
  def save(freedbRecord, category, discid)
    @freedbRecord = freedbRecord
    @category = category
    @discid = discid
    saveDiscid()
  end

  # return the file location
  def outputFile ; return @outputFile ; end

private

  # if $HOME/.cddb/<category>/<discid> does nog exist, create it
  def saveDiscid
    @outputFile = File.join(ENV['HOME'], '.cddb', @category,
@discid)
    @file.write(@outputFile, @freedbRecord, force=false)
  end
end
