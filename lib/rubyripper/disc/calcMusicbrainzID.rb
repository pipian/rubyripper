#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2011  Ian Jacobi (pipian@pipian.com)
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

# Used to hash the DiscID
require 'openssl'
# Used to do final encoding of DiscID
require 'base64'

require 'rubyripper/disc/disc'

# class that gets the MusicBrainz web service lookup path
class CalcMusicbrainzID

  # setup some references to needed objects
  def initialize(disc)
    @disc = disc
  end

  # fetch the MusicBrainz web service URL
  def musicbrainzLookupPath
    getMusicBrainzLookupPath() if @musicbrainzLookupPath.nil?
    @musicbrainzLookupPath
  end

  # fetch the discid
  def discid
    getMusicBrainzLookupPath() if @musicbrainzLookupPath.nil?
    @discid
  end

private

  # try to calculate it ourselves, prefer cd-info if available
  def getMusicBrainzLookupPath()
    @scan = @disc.advancedTocScanner
    @scan.scan
    setDiscId()
    buildMusicBrainzLookupPath()
  end

  # Calculate the discid using standard algorithm
  # (http://musicbrainz.org/doc/Disc_ID_Calculation)
  def setDiscId
    # Not necessarily best way to get first/last track number but...

    # cdparanoia is missing dataTracks, so I hope that's not all you
    # have to go on!
    if @scan.respond_to?(:dataTracks)
      @firstTrack = (@scan.dataTracks + [@scan.firstAudioTrack]).min
      @lastTrack = @firstTrack + @scan.audiotracks + @scan.dataTracks.length-1
      lastTrackIsData = @scan.dataTracks.include?(@lastTrack)
    else
      @firstTrack = @scan.firstAudioTrack
      @lastTrack = @firstTrack + @scan.audiotracks - 1
      lastTrackIsData = false
    end

    # MusicBrainz's discid (currently) ignores ONLY the last track if
    # the disc has more than one session first track in the last
    # session is a data track.  This probably isn't really the
    # behavior as suggested in the page above (let alone that of the
    # Windows implementations before XP), but it's the behavior of the
    # canonical implementation, libdiscid.
    #
    # The leadout depends on us correctly determining this, because
    # (as implemented in libdiscid), if we have such a CD, we should
    # ALSO assume that the lead-out is 152 seconds (11400
    # frames/blocks) before the start of the first track in the last
    # session.
    #
    # We don't implement this EXACTLY, but rather implement an
    # approximation: if the last track is a data track, we assume that
    # it is the ONLY track in the last session of the disc.  This
    # assumption holds for practically every multi-session disc I've
    # ever seen, but it could still break in rare cases.  (e.g. I
    # haven't had much experience with "defective" TOCs on Copy
    # Control CDs)
    @offsets = [0] * 100
    if @lastTrack != @firstTrack and lastTrackIsData
      @offsets[0] = @scan.getStartSector(@lastTrack) - 11400 + 150
      @lastTrack -= 1
    else
      @offsets[0] = @scan.totalSectors + 150
    end

    (@firstTrack..@lastTrack).each do |tracknumber|
      @offsets[tracknumber] = @scan.getStartSector(tracknumber) + 150
    end

    digestData = String.new
    digestData << '%02X' % @firstTrack
    digestData << '%02X' % @lastTrack
    @offsets.each do |offset|
      digestData << '%08X' % offset
    end
    @discid = OpenSSL::Digest.digest('SHA1', digestData)
    @discid = Base64.strict_encode64(@discid)
    @discid.gsub!(/[+\\=\/]/, {'+' => '.', '/' => '_', '=' => '-'})
  end

  # now build the MusicBrainz lookup path (relative to the web services root)
  # this consists of:
  # * 'discid/'
  # * discid
  # * '?toc='
  # * the un-hashed decimal values used to construct the discid separated by +
  def buildMusicBrainzLookupPath
    @musicbrainzLookupPath = String.new
    @musicbrainzLookupPath << 'discid/'
    @musicbrainzLookupPath << "#{@discid}"
    @musicbrainzLookupPath << '?toc='

    @musicbrainzLookupPath << "#{@firstTrack}+#{@lastTrack}"
    (0..@lastTrack).each do |tracknumber|
      @musicbrainzLookupPath << "+#{@offsets[tracknumber]}"
    end
  end
end
