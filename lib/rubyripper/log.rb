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

require 'rubyripper/preferences/main'
require 'rubyripper/modules/audioCalculations'

# The Log class is responsible for
# * updating the log files
# * keeping track of the reading trials
# * passing update messages to the user interface

class Log
  include AudioCalculations
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :rippingErrors, :encodingErrors, :short_summary
  attr_writer :encodingErrors

  def initialize(disc, fileScheme, userInterface, updatePercForEachTrack, prefs=nil, fileAndDir=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @file = fileAndDir ? fileAndDir : FileAndDir.instance
    @md = disc.metadata
    @fileScheme = fileScheme
    @ui = userInterface
    @updatePercForEachTrack = updatePercForEachTrack
  end

  def start()
    createLog()
    @problem_tracks = Hash.new # key = tracknumber, value = new dictionary with key = seconds_chunk, value = [amount_of_chunks, trials_needed]
    @not_corrected_tracks = Array.new # Array of tracks that weren't corrected within the maximum amount of trials set by the user
    @encoding_progress = 0.0
    @encodingErrors = false
    @rippingErrors = false
    @short_summary = _("Artist : %s\nAlbum: %s\n") % [@md.artist, @md.album]
  end

  def createLog
    @logfiles = Array.new
    @prefs.codecs.each do |codec|
      logfile = @fileScheme.getLogFile(codec)
      @file.createDirForFile(logfile)
      @logfiles << File.open(logfile, 'a')
    end
  end

  # update the ripping progress in the gui
  def updateRippingProgress(trackFinished=nil)
    @progressRip ||= 0.0
    @progressRip += @updatePercForEachTrack[trackFinished] if trackFinished

    # prevent rounding problem
    @progressRip = 1.0 if @progressRip > 0.99

    @ui.update("ripping_progress", @progressRip)
  end

  # update the encoding percentage of the gui
  def updateEncodingProgress(trackFinished=nil, numberOfCodecs=nil)
    @progressEncoding ||= 0.0
    @progressEncoding += (@updatePercForEachTrack[trackFinished] / numberOfCodecs) if trackFinished

    # prevent rounding problem
    @progressEncoding = 1.0 if @progressEncoding > 0.99

    @ui.update("encoding_progress", @progressEncoding)
  end
 
  def update(type, message=nil)
    @ui.update(type, message)
  end

  # Print out a rip-level error (e.g. an abort)
  def error(message)
    add("#{message}\n")
  end

  def finished
    summary()
    deleteLogfiles if @prefs.noLog
    @fileScheme.cleanTempDir()
    @ui.update("finished", noProblems = !(@rippingErrors || @encodingErrors))
  end

  def <<(message)
    add(message)
  end

  # Add a message to the logging file + update the gui
  def add(message, calling_function = false)
    @logfiles.each{|logfile| logfile.print(message); logfile.flush()} # Append the messages to the logfiles
    @ui.update("log_change", message)
  end

  # Format a list of bad sectors in a rip.
  def listBadSectors(message, errors)
    add("       #{message}\n")   
    sequential = false
    lastSector = false
    
    errors.each_pair do |key, value|
      # TODO: Is this right?
      if lastSector != key / BYTES_AUDIO_FRAME - 1
        
        # Print the last sector in the last sequence of bad sectors
        add(toTime(lastSector)) if sequential      
        # New sequence starts.
        add("\n") if lastSector != false
        add(toTime(key))
        
        sequential = false
      elsif lastSector == key / BYTES_AUDIO_FRAME - 1 and !sequential
        # In an actual sequence, rather than a one-off
        add("-")
        sequential = true
      end
      lastSector = key / BYTES_AUDIO_FRAME
    end
    add("\n")
  end

  def mismatch(track, trial, indexes_with_errors, size, length)
    if !@problem_tracks.key?(track) #First time we encounter this track (Secure_rip->analyzeFiles() )
      @problem_tracks[track] = Hash.new # create the Hash for the track
      indexes_with_errors.each do |index_of_chunk|
        seconds = index_of_chunk / BYTES_AUDIO_SECOND
        if !@problem_tracks[track].key?(seconds)
          @problem_tracks[track][seconds] = [1, trial] # different_chunks, trial. First time we encounter this position, so different_chunks = 1
        else
          @problem_tracks[track][seconds][0] += 1 # one more chunk at the same second
        end
      end
    else
      indexes_with_errors.each do |index_of_chunk|
        seconds = index_of_chunk / BYTES_AUDIO_SECOND # position of chunk rounded in seconds, each second = 176400 bytes
        @problem_tracks[track][seconds][1] = trial #Update the amount of trials needed
      end
    end
    if trial == 0; @not_corrected_tracks << track end #Reached maxtries and still got errors
  end

  # All sectors matched message
  def allSectorsMatched()
    add("     #{_("All chunks matched!")}\n")
  end

  def correctedMismatches(reqMatchesErrors)
    add("     #{_("Corrected all sector mismatches! (%s matches found for each chunk)") % [reqMatchesErrors]}\n")
  end

  def newTrack(track=nil)
    @prefs.image ? add(_("Disc Image\n\n")) : add(_("Track %2d\n\n") % [track])
    @prefs.codecs.each{|codec| add("     " + _("File name %s\n") % [@fileScheme.getFile(codec, track)])}
    add("\n")
  end

  def finishTrial(trial, timeElapsed, trackLength)
    add("     " + _("Trial %s: %s seconds (%sx)\n") % [trial, timeElapsed.to_i, sprintf("%.2f", trackLength.to_f / (timeElapsed.to_f * 75))])
  end

  def finishTrack(level, crcs, status, correctedcrc=nil)
    add("\n")
    add("     #{_("Peak level %.1f %%") % [level]}\n")
    crcs.each_index do |i|
      if i == 0
        add("     #{_("Trial %s (Copy) CRC %s") % [i + 1, crcs[i]]}\n")
      else
        add("     #{_("Trial %s (Test) CRC %s") % [i + 1, crcs[i]]}\n")
      end
    end
    if !correctedcrc.nil?
      add("     #{_("Corrected CRC %s") % [correctedcrc]}\n")
    end
    add("     #{status}\n\n")
  end

  def copyMD5(md5sum)
    add("     " + _("Copy MD5: %s\n\n") % [md5sum])
  end

  def summary() #Give an overview of errors
    if @encodingErrors ; @short_summary += _("\nWARNING: ENCODING ERRORS WERE DETECTED\n") ; end
    @short_summary += _("\nRIPPING SUMMARY\n\n")

    @short_summary += _("All chunks were tried to match at least %s times.\n") % [@prefs.reqMatchesAll]
    if @prefs.reqMatchesAll != @prefs.reqMatchesErrors
      @short_summary += _("Chunks that differed after %s trials,") % [@prefs.reqMatchesAll]
      @short_summary += _("\nwere tried to match %s times.\n") % [@prefs.reqMatchesErrors]
    end

    if @problem_tracks.empty?
      add(_("No errors occurred"))
      @short_summary += _("None of the tracks gave any problems\n")
    elsif @not_corrected_tracks.size != 0
      add(_("There were errors which could not be corrected"))
      @short_summary += _("Some track(s) could NOT be corrected within the maximum amount of trials\n")
      @not_corrected_tracks.each do |track|
        @rippingErrors = true
        @short_summary += _("Track %s could NOT be corrected completely\n") % [track]
      end
    else
      # Is this correct for a track where errors were corrected in EAC?
      add(_("There were errors which required correction"))
      @short_summary += _("Some track(s) needed correction,but could\nbe corrected within the maximum amount of trials\n")
    end
    add("\n")
    if @encodingerrors ; add(_("There were errors during encoding\n")) ; end

    if !@problem_tracks.empty? # At least some correction was necessary
      @short_summary += _("The exact positions of the suspicious chunks\ncan be found in the ripping log\n")
    end
    @logfiles.each{|logfile| logfile.close} #close all the files
  end

  # delete the logfiles if no errors occured
  def deleteLogfiles
    if @problem_tracks.empty? && !@encodingErrors
      @logfiles.each{|logfile| File.delete(logfile.path)}
    end
  end
end
