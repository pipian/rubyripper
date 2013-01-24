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

# TODO perhaps call the cuesheet generation as well

require 'rubyripper/preferences/main'
require 'rubyripper/system/execute'
require 'rubyripper/system/fileAndDir'
require 'rubyripper/errors'
require 'rubyripper/modules/audioCalculations'

class ScanDiscCdrdao
  include AudioCalculations
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :error, :dataTracks, :discType, :tracks, :artist, :album

  def initialize(execute=nil, prefs=nil, fileAndDir=nil)
    @exec = execute ? execute : Execute.new()
    @prefs = @prefs = prefs ? prefs : Preferences::Main.instance
    @fileAndDir = fileAndDir ? fileAndDir : FileAndDir.instance()
    @discType = nil
  end

  # The scan is called after the initial scan in Disc.
  # scan the disc and parse the resulting file
  def scanInBackground()
    @cdrdaoThread = Thread.new do
      prepareCdrdaoScan()
      launchCdrdaoScan()
      setVariables()
      parseCdrdaoFile() if cdrdaoScanSuccesfull && cdrdaoFileValid
    end
  end
 
  # The thread is joined in the Rubyripper class.
  # Let the ripping wait for the process to finish, print the info to the screen (log)
  def joinWithMainThread(log)
    @log = log
    if @error.nil?
      scan() if @cdrdaoThread.nil?
      displayStartMessage()
      @cdrdaoThread.join()
      displayScanResults()
    else
      @log << @error
    end
  end
  
  # some discs have a silence tag at the start of the disc
  def getSilenceSectors
    return @silence
  end

  # return the pregap if found, otherwise return 0
  def getPregapSectors(track)
    @preGap.key?(track) ? @preGap[track] : 0
  end

  # return if a track has pre-emphasis
  def preEmph?(track)
    @preEmphasis.include?(track)
  end

  def getTrackname(track)
    @trackNames.key?(track) ? @trackNames[track] : String.new
  end

  def getVarArtist(track)
    @varArtists.key?(track) ? @varArtists[track] : String.new
  end
  
  def getIsrcForTrack(track)
    @trackIsrc.key?(track) ? @trackIsrc[track] : String.new
  end

private

  def prepareCdrdaoScan
    @tempfile = @exec.getTempFile("#{File.basename(@prefs.cdrom)}.toc")
    cleanupTempFile()
  end
  
  def cleanupTempFile
    @fileAndDir.remove(@tempfile) if @fileAndDir.exist?(@tempfile)
  end

  def launchCdrdaoScan
    @result = @exec.launch("cdrdao read-toc --device #{@prefs.cdrom} \"#{@tempfile}\"")
  end
  
  def cdrdaoScanSuccesfull
    @error = case @result
      when nil then Errors.binaryNotFound('cdrdao')
      when /ERROR: Unit not ready, giving up./ then Errors.noDiscInDrive(@prefs.cdrom)
      when /Usage: cdrdao/ then Errors.wrongParameters('cdrdao')
      when /ERROR: Cannot setup device/ then Errors.unknownDrive(@prefs.cdrom)
      else nil
    end   
    @error.nil?
  end
  
  def cdrdaoFileValid
    return false unless @fileAndDir.exists?(@tempfile)
    @contents = @fileAndDir.read(@tempfile)
    cleanupTempFile()
  end
  
  def setVariables
    @trackIsrc = Hash.new
    @preEmphasis = Array.new
    @dataTracks = Array.new
    @preGap = Hash.new
    @trackNames = Hash.new
    @varArtists = Hash.new
  end

  def parseCdrdaoFile
    track = nil
    @contents.each_line do |line|
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
      elsif line[0..3] == 'ISRC'
        @trackIsrc[track] = line[4..-1].strip()[1..-2] #exclude quotes
      end
    end
    @tracks = track
  end

  def displayStartMessage
    @log << _("\nADVANCED TOC ANALYSIS (with cdrdao)\n")
    @log << _("...please be patient, this may take a while\n\n")
  end

  def displayScanResults
    if not @error.nil?
      @log << @error
      return false
    end
    
    if @preEmphasis.empty? && @preGap.empty? && @silence.nil? && @dataTracks.empty?
      @log << _("No pregap, silence, pre-emphasis or data track detected\n\n")
      return true
    end

    unless @silence.nil?
      @log << _("Silence detected for disc : %s sectors\n") % [@silence]
    end
    
    unless @tracks.nil?
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
    end

    #set an extra whiteline before starting to rip
    @log << "\n"
  end
end
