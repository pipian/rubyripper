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

# Store all metadata
class Metadata
  attr_accessor :artist, :album, :genre, :year, :tracklist, :varArtist,
      :extraDiscInfo, :discid

  def initialize
    @artist = _('Unknown')
    @album = _('Unknown')
    @genre = _('Unknown')
    @year = '0'
    @extraDiscInfo = ''
    @discid = ''

    # trackNumber => name
    @tracklist = Hash.new
    @varArtist = Hash.new
  end

  def trackname(number)
    return _('Track %s') % [number] unless @tracklist[number]
    @tracklist[number]
  end

  def getVarArtist(number)
    return _('Unknown') unless @varArtist[number]
    @varArtist[number]
  end

  def setVarArtist
    @tracklist.each_key{|key| @varArtist[key] = _('Unknown')}
  end

  def unsetVarArtist ; @varArtist = Hash.new ; end

  def various? ; @varArtist.size > 0 ; end
end
