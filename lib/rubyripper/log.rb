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

# The Log class is responsible for
# * updating the log files
# * keeping track of the reading trials
# * passing update messages to the user interface

class Log
attr_reader :rippingErrors, :encodingErrors, :short_summary
attr_writer :encodingErrors

  def initialize(preferences, disc, outputFile, userInterface, updatePercForEachTrack)
    @prefs = preferences
    @md = disc.metadata
    @out = outputFile
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
    ['flac', 'vorbis', 'mp3', 'wav', 'other'].each do |codec|
      @logfiles << File.open(@out.getLogFile(codec), 'a') if @prefs.send(codec)
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

  def finished
    summary()
    deleteLogfiles if @prefs.noLog
    @out.cleanTempDir()
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

  # Add a message to the logging file
  def addLog(message, summary = false)
    @logfiles.each{|logfile| logfile.print(message); logfile.flush()} # Append the messages to the logfiles
    if summary ; @short_summary += message end
  end

  def mismatch(track, trial, indexes_with_errors, size, length)
    if !@problem_tracks.key?(track) #First time we encounter this track (Secure_rip->analyzeFiles() )
      @problem_tracks[track] = Hash.new # create the Hash for the track
      indexes_with_errors.each do |index_of_chunk|
        seconds = index_of_chunk / 176400 # position of chunk rounded in seconds, each second = 176400 bytes
        if !@problem_tracks[track].key?(seconds)
          @problem_tracks[track][seconds] = [1, trial] # different_chunks, trial. First time we encounter this position, so different_chunks = 1
        else
          @problem_tracks[track][seconds][0] += 1 # one more chunk at the same second
        end
      end
    else
      indexes_with_errors.each do |index_of_chunk|
        seconds = index_of_chunk / 176400 # position of chunk rounded in seconds, each second = 176400 bytes
        @problem_tracks[track][seconds][1] = trial #Update the amount of trials needed
      end
    end
    if trial == 0; @not_corrected_tracks << track end #Reached maxtries and still got errors
  end

  def summary() #Give an overview of errors
    if @encodingErrors ; addLog(_("\nWARNING: ENCODING ERRORS WERE DETECTED\n"), true) end
    addLog(_("\nRIPPING SUMMARY\n\n"), true)

    addLog(_("All chunks were tried to match at least %s times.\n") % [@prefs.reqMatchesAll], true)
    if @prefs.reqMatchesAll != @prefs.reqMatchesErrors
      addLog(_("Chunks that differed after %s trials,") % [@prefs.reqMatchesAll], true)
      addLog(_("\nwere tried to match %s times.\n") % [@prefs.reqMatchesErrors], true)
    end

    if @problem_tracks.empty?
      addLog(_("None of the tracks gave any problems\n"), true)
    elsif @not_corrected_tracks.size != 0
      addLog(_("Some track(s) could NOT be corrected within the maximum amount of trials\n"), true)
      @not_corrected_tracks.each do |track|
        @rippingErrors = true
        addLog(_("Track %s could NOT be corrected completely\n") % [track], true)
      end
    else
      addLog(_("Some track(s) needed correction,but could\nbe corrected within the maximum amount of trials\n"), true)
    end

    if !@problem_tracks.empty? # At least some correction was necessary
      position_analyse()
      @short_summary += _("The exact positions of the suspicious chunks\ncan be found in the ripping log\n")
    end
    @logfiles.each{|logfile| logfile.close} #close all the files
  end

  def position_analyse() # Give an overview of suspicion position in the logfile
    addLog(_("\nSUSPICIOUS POSITION ANALYSIS\n\n"))
    addLog(_("Since there are 75 chunks per second, after making the notion of the\n"))
    addLog(_("suspicious position, the amount of initially mismatched chunks for\nthat position is shown.\n\n"))
    @problem_tracks.keys.sort.each do |track| # For each track show the position of the files, how many chunks of that position and amount of trials needed to solve
      addLog(_("TRACK %s\n") % [track])
      @problem_tracks[track].keys.sort.each do |length| #length = total seconds of suspicious position
        minutes = length / 60 # ruby math -> 70 / 60 = 1 (how many times does 60 fit in 70)
        seconds = length % 60 # ruby math -> 70 % 60 = 10 (leftover)
        if @problem_tracks[track][length][1] != 0
          addLog(_("\tSuspicious position : %s:%s (%s x) (CORRECTED at trial %s)\n") % [sprintf("%02d", minutes), sprintf("%02d", seconds), @problem_tracks[track][length][0], @problem_tracks[track][length][1] + 1])
        else # Position could not be corrected
          addLog(_("\tSuspicious position : %s:%s (%sx) (COULD NOT BE CORRECTED)\n") % [ sprintf("%02d", minutes), sprintf("%02d", seconds), @problem_tracks[track][length][0]])
        end
      end
    end
  end

  # delete the logfiles if no errors occured
  def deleteLogfiles
    if @problem_tracks.empty? && !@encodingErrors
      @logfiles.each{|logfile| File.delete(logfile.path)}
    end
  end
end
