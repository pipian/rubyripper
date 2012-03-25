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

# The Encode class is responsible the threads for the diverse codecs.

require 'thread' # for the sized queue object
require 'monitor' # for the monitor object

require 'rubyripper/codecs/main'
require 'rubyripper/system/fileAndDir'
require 'rubyripper/system/dependency'
require 'rubyripper/system/execute'
require 'rubyripper/preferences/main'

class Encode
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_writer :cancelled

  def initialize(log, trackSelection, disc, scheme, file=nil, deps=nil, exec=nil, prefs=nil)
    @log = log
    @trackSelection = trackSelection
    @scheme = scheme
    @file = file ? file : FileAndDir.instance
    @deps = deps ? deps : Dependency.instance
    @exec = exec ? exec : Execute.new()
    @prefs = prefs ? prefs : Preferences::Main.instance
    @codecs = [] ; @prefs.codecs.each{|codec| @codecs << Codecs::Main.new(codec, disc, scheme)}
    setHelpVariables()
  end
  
  def setHelpVariables
    @cancelled = false
    @progress = 0.0
    @threads = []
    @queue = SizedQueue.new(@prefs.maxThreads) if @prefs.maxThreads != 0
    @lock = Monitor.new

    # all encoding tasks are saved here, to determine when to delete a wav
    @tasks = Hash.new ; @trackSelection.each{|track| @tasks[track] = @prefs.codecs}
  end

  # is called when a track is ripped succesfully
  def addTrack(track)
    startEncoding(track) unless waitingForNormalizeToFinish(track)
  end

  # encode track when normalize is finished
  def startEncoding(track)
    # mark the progress bar as being started
    @log.updateEncodingProgress() if track == @trackSelection[0]
    return false if @cancelled != false
    
    @codecs.each do |codec|
      if @prefs.maxThreads == 0
        encodeTrack(track, codec)
      else
        puts "DEBUG: Adding track #{track} (#{codec.name}) to the queue.." if @prefs.debug
        @queue << 1 # add a value to the queue, if full wait here.
        @threads << Thread.new do
          encodeTrack(track, codec)
          puts "DEBUG: Removing track #{track} (#{codec.name}) from the queue.." if @prefs.debug
          @queue.shift() # move up in the queue to the first waiter
        end
      end
    end

    #give the signal we're finished
    if (@prefs.image || track == @trackSelection[-1]) && @cancelled == false
      @threads.each{|thread| thread.join()}
      @log.finished()
    end
  end

  # respect the normalize setting
  def waitingForNormalizeToFinish(track)
    return false if @prefs.normalizer != 'normalize'

    if @prefs.gain == 'track'
      command = "normalize \"#{@scheme.getTempFile(track, 1)}\""
      @exec.launch(command)
      waiting = false
    elsif @prefs.gain == 'album' && @trackSelection[-1] != track
      waiting = true
    elsif @prefs.gain == 'album' && @trackSelection[-1] == track
      command = "normalize -b \"#{File.join(@scheme.getTempDir(),'*.wav')}\""
      @exec.launch(command)
      # now the wavs are altered, the encoding can start
      @trackSelection.each{|track| startEncoding(track)}
      waiting = true
    end
    return waiting
  end

  # call the specific codec function for the track and apply replaygain if desired
  def encodeTrack(track, codec)
    @log.encodingErrors = true if @exec.launch(codec.command(track)).empty?
  
    if @prefs.normalizer == "replaygain"
      if @prefs.gain == "track"
        @exec.launch(codec.replaygain(track)) unless codec.replaygain(track).empty?
      elsif not @tasks.values.flatten.include?(codec.name)
        @exec.launch(codec.replaygainAlbum()) unless codec.replaygainAlbum.empty?
      end
    end
    
    @lock.synchronize do
      @tasks[track].delete(codec.name)
      @file.delete(@scheme.getTempFile(track)) if @tasks[track].empty?
      @log.updateEncodingProgress(track, @codecs.size)
    end
  end
end

#    elsif codec == 'other' && @prefs.settingsOther != nil ; doOther(track)
# 
#   def doOther(track)
#     filename = @out.getFile(track, 'other')
#     command = @prefs.settingsOther.dup
# 
#     command.force_encoding("UTF-8") if command.respond_to?("force_encoding")
#     command.gsub!('%n', sprintf("%02d", track)) if track != "image"
#     command.gsub!('%f', 'other')
# 
#     if @md.various?
#       command.gsub!('%a', @tags.getVarArtist(track))
#       command.gsub!('%va', @tags.artist)
#     else
#       command.gsub!('%a', @tags.artist)
#     end
# 
#     command.gsub!('%b', @tags.album)
#     command.gsub!('%g', @tags.genre)
#     command.gsub!('%y', @tags.year)
#     command.gsub!('%t', @tags.getTrackname(track))
#     command.gsub!('%i', @out.getTempFile(track, 1))
#     command.gsub!('%o', @out.getFile(track, 'other'))
#     checkCommand(command, track, 'other')
#   end
# 
# TODO There used to be an issue with mp3 that the tags should be
# TODO latin1 encoded, though the outputfile should be UTF8
# TODO It is possible lame has itself fixed the error
