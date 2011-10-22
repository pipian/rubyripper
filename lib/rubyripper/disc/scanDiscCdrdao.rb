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

# The scanDiscCdrdao class helps detecting all special audio-cd
# features as hidden tracks, pregaps, etcetera. It does so by
# analyzing the output of cdrdao's TOC output. The class is only
# opened when the user has the cuesheet enabled. This is so because
# there is not much of an advantage of detecting pregaps when
# they're just added to the file anyway. You want to detect
# the gaps so you can reproduce the original disc exactly. The
# cuesheet is necessary to store the gap info.
# The scanning will take about 1 - 2 minutes.

# TODO handle the extra thread from within this class
# TODO perhaps call the cuesheet generation as well

require 'rubyripper/preferences/main'

class ScanDiscCdrdao
attr_reader :log, :status, :dataTracks, :discType, :tracks,
    :artist, :album

  def initialize(execute, prefs=nil)
    @prefs = @prefs = prefs ? prefs : Preferences::Main.instance
    @exec = execute
  end

  # scan the disc and parse the resulting file
  def scan
    @tempfile = nil ; @cdrom = nil

    @output = getOutput()
    if isValidQuery()
      @status = 'ok'
      setVars()
      parseQuery()
      makeLog() unless @tracks.nil?
    end
  end

  # some discs have a silence tag at the start of the disc
  def getSilenceSectors
    assertScanFinished('getSilenceSectors')
    return @silence
  end

  # return the pregap if found, otherwise return 0
  def getPregapSectors(track)
    assertScanFinished('getPregapSectors')
    @preGap.key?(track) ? @preGap[track] : 0
  end

  # return if a track has pre-emphasis
  def preEmph?(track)
    assertScanFinished('preEmph?')
    @preEmphasis.include?(track)
  end

  def getTrackname(track)
    assertScanFinished('getTrackname')
    @trackNames.key?(track) ? @trackNames[track] : String.new
  end

  def getVarArtist(track)
    assertScanFinished('getVarArtist')
    @varArtists.key?(track) ? @varArtists[track] : String.new
  end

private

  def assertScanFinished(name)
    raise "Can't #{name} when scanDiscCdparanoia status is not ok!" unless @status == 'ok'
  end

  # return the cdrom drive
  def cdrom
    @cdrom ||= @prefs.cdrom
  end

  # return a temporary filename, based on the drivename to make it unique
  def tempfile
    @tempfile ||= @exec.getTempFile("#{File.basename(cdrom)}.toc")
  end

  # get all the cdrdao info
  def getOutput
    command = "cdrdao read-toc --device #{cdrom} \"#{tempfile()}\""
    command += " 2>&1" unless @prefs.verbose

    @exec.launch(command, tempfile())
    @exec.status == 'ok' ? @exec.readFile() : nil
  end

  # check if the output is valid
  def isValidQuery
    case @output
      when nil then @status = 'notInstalled'
      when /ERROR: Unit not ready, giving up./ then @status = 'noDiscInDrive'
      when /Usage: cdrdao/ then @status = 'wrongParameters'
      when /ERROR: Cannot setup device/ then @status = 'unknownDrive'
    end

    return @status.nil?
  end

  # set some variables
  def setVars
    @log = Array.new
    @preEmphasis = Array.new
    @dataTracks = Array.new
    @preGap = Hash.new
    @trackNames = Hash.new
    @varArtists = Hash.new
  end

  # minutes:seconds:sectors to sectors
  def toSectors(time)
    count = 0
    minutes, seconds, sectors = time.split(':')
    count += sectors.to_i
    count += (seconds.to_i * 75)
    count += (minutes.to_i * 60 * 75)
    return count
  end

  # read the file of cdrdao into the scan Hash
  def parseQuery
    track = nil
    @output.each_line do |line|
      if line[0..1] == 'CD' && @discType.nil?
        @discType = line.strip()
      elsif !track && line =~ /TITLE /
        @artist, @album = $'.strip()[1..-2].split(/\s\s+/)
      elsif !track && line =~ /SILENCE /
        @silence = toSectors($'.strip)
      elsif line =~ / Track /
        track = $'.strip().to_i
      elsif line =~ /TRACK DATA/
        @dataTracks << track
      elsif line[0..11] == 'PRE_EMPHASIS'
        @preEmphasis << track
      elsif line =~ /START /
        @preGap[track] = toSectors($'.strip)
      elsif line =~ /TITLE /
        @trackNames[track] = $'.strip()[1..-2] #exclude quotes
      elsif track && line =~ /PERFORMER /
        if $'.strip().length > 2
          @varArtists[track] = $'.strip()[1..-2] #exclude quotes
        end
      end
    end
    @tracks = track
  end

  # report all special cases
  def makeLog
    if @preEmphasis.empty? && @preGap.empty? && @silence.nil?
      @log << _("No pregaps, silences or pre-emphasis detected\n")
      return true
    end

    @log << _("Silence detected for disc : %s sectors\n") % [@silence]

    (1..@tracks).each do |track|
      @log << _("Pregap detected for track %s : %s sectors\n") %
      [track, @preGap[track]] if @preGap.key?(track)

      # pre emphasis detected?
      @log << ("Pre_emphasis detected for track %s\n") %
      [track] if @preEmphasis.include?(track)

      # is the track marked as data track?
      @log << _("Track %s is marked as a DATA track\n") %
      [track] if @dataTracks.include?(track)
    end

    #set an extra whiteline before starting to rip
    @log << "\n"
  end
end
