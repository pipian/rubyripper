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

require 'digest/md5' # Needed for secure class, only have to load them ones here.
require 'rubyripper/system/dependency'
require 'rubyripper/system/execute'
require 'rubyripper/preferences/main'

# The SecureRip class is mainly responsible for:
# * Managing cdparanoia to fetch the files
# * Comparing the fetched files
# * Repairing the files if necessary

class SecureRip
  attr_writer :cancelled

  BYTES_WAV_CONTAINER = 44 # to store the type of wav file
  BYTES_AUDIO_SECTOR = 2352 # conform cdparanoia

  def initialize(trackSelection, disc, outputFile, log, encoding, deps=nil, exec=nil, prefs=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @trackSelection = trackSelection
    @disc = disc
    @out = outputFile
    @log = log
    @encoding = encoding
    @deps = deps ? deps : Dependency.new()
    @exec = exec ? exec : Execute.new(@deps)
    @cancelled = false
    @reqMatchesAll = @prefs.reqMatchesAll # Matches needed for all chunks
    @reqMatchesErrors = @prefs.reqMatchesErrors # Matches needed for chunks that didn't match immediately
    @sizeExpected = 0
    @timeStarted = Time.now # needed for a time break after 30 minutes
  end

  def ripTracks
    @log.updateRippingProgress() # Give a hint to the gui that ripping has started

    @trackSelection.each do |track|
      break if @cancelled == true
      puts "Ripping track #{track}" if @prefs.debug && !@prefs.image
      puts "Ripping image" if @prefs.debug && @prefs.image
      ripTrack(track)
    end

    @exec.eject(@prefs.cdrom) if @prefs.eject
  end


  # Due to a bug in cdparanoia the -Z setting has to be replaced for last track.
  # This is only needed when an offset is set. See issue nr. 13.
  def checkParanoiaSettings(track)
    if @prefs.rippersettings.include?('-Z') && @prefs.offset != 0
      if @prefs.image || track == @disc.audiotracks
        @prefs.rippersettings.gsub!(/-Z\s?/, '')
      end
    end
  end

  # rip one output file
  def ripTrack(track)
    checkParanoiaSettings(track)

    #reset next three variables for each track
    @errors = Hash.new()
    @filesizes = Array.new
    @trial = 0

    # first check if there's enough size available in the output dir
    if sizeTest(track)
      if main(track)
        deEmphasize(track)
        @encoding.addTrack(track)
      else
        return false
      end #ready to encode
    end
  end

  # check if the track needs to be corrected
  # the de-emphasized file needs another name
  # when sox is finished move it back to the original name
  def deEmphasize(track)
    if @prefs.createCue && @prefs.preEmphasis == "sox" &&
      @disc.toc.hasPreEmph(track) && @deps.installed?("sox")
      @exec.launch("sox #{@out.getTempFile(track, 1)} #{@out.getTempFile(track, 2)}")
      if @exec.status == 'ok'
        FileUtils.mv(@out.getTempFile(track, 2), @out.getTempFile(track, 1))
      else
        puts "sox failed somehow."
      end
    end
  end

  def sizeTest(track)
    puts "Expected filesize for #{if track == "image" ; track else "track #{track}" end} \
is #{@disc.getFileSize(track)} bytes." if @prefs.debug

    if @deps.installed?('df')
      output = @exec.launch("df \"#{@out.getDir()}\"", filename=false, noTranslations=true)
      freeDiskSpace = output[1].split()[3].to_i
      puts "Free disk space is #{freeDiskSpace} MB" if @prefs.debug
      if @disc.getFileSize(track) > freeDiskSpace*1000
        @log.add(_("Not enough disk space left! Rip aborted"))
        return false
      end
    end
    return true
  end

  def main(track)
    @reqMatchesAll.times{if not doNewTrial(track) ; return false end} # The amount of matches all sectors should match
    analyzeFiles(track) #If there are differences, save them in the @errors hash

    while @errors.size > 0
      if @trial > @prefs.maxTries && @prefs.maxTries != 0
        @log.add(_("Maximum tries reached. %s chunk(s) didn't match the required %s times\n") % [@errors.length, @reqMatchesErrors])
        @log.add(_("Will continue with the file we've got so far\n"))
        @log.mismatch(track, 0, @errors.keys, @disc.getFileSize(track), @disc.getLengthSector(track)) # zero means it is never solved.
        break # break out loop and continue using trial1
      end

      doNewTrial(track)
      break if @cancelled == true

      # update the erronous positions for the new trial
      readErrorPos(track)

      # if enough trials are done to possibly allow corrections
      # for example is trial = 3 and only 2 matches are required a match can happen
      correctErrorPos(track) if @trial > @reqMatchesErrors

    end

    getDigest(track) # Get a MD5-digest for the logfile
    @log.updateRippingProgress(track)
    return true
  end

  def doNewTrial(track)
    fileOk = false

    while (!@cancelled && !fileOk)
      @trial += 1
      rip(track)
      if fileCreated(track) && testFileSize(track)
        fileOk = true
      end
    end

    # when cancelled fileOk will still be false
    return fileOk
  end

  def fileCreated(track) #check if cdparanoia outputs wav files (passing bad parameters?)
    if not File.exist?(@out.getTempFile(track, @trial))
      @log.update("error", _("Cdparanoia doesn't output wav files.\nCheck your settings please."))
      return false
    end
    return true
  end

  def testFileSize(track) #check if wavfile is of correct size
    sizeDiff = @disc.getFileSize(track) - File.size(@out.getTempFile(track, @trial))

    # at the end the disc may differ 1 sector on some drives (2352 bytes)
    if sizeDiff == 0
      # expected size matches exactly
    elsif sizeDiff < 0
      puts "More sectors ripped than expected: #{sizeDiff / BYTES_AUDIO_SECTOR} sector(s)" if @prefs.debug
    elsif @prefs['offset'] != 0 && (track == "image" || track == @disc.audiotracks)
      @log.add(_("The ripped file misses %s sectors.\n") % [sizeDiff / BYTES_AUDIO_SECTOR.to_f])
      @log.add(_("This is known behaviour for some drives when using an offset.\n"))
      @log.add(_("Notice that each sector is 1/75 second.\n"))
    elsif @cancelled == false
      if @prefs.debug
        puts "Some sectors are missing for track #{track} : #{sizeDiff} sector(s)"
        puts "Filesize should be : #{@disc.getFileSize(track)}"
      end

      #someone might get out of free diskspace meanwhile
      @cancelled = true if not sizeTest(track)

      File.delete(@out.getTempFile(track, @trial)) # Delete file with wrong filesize
      @trial -= 1 # reset the counter because the filesize is not right
      @log.add(_("Filesize is not correct! Trying another time\n"))
      return false
    end
    return true
  end

  # Start and close the first file comparisons
  def analyzeFiles(track)
    start = Time.now()
    @log.add(_("Analyzing files for mismatching chunks"))
    compareSectors(track) unless filesEqual?(track)
    @log.add(_(" (%s second(s))\n") %[(Time.now - start).to_i])

    # Remove the files now we analyzed them. Differences are saved in memory.
    (@reqMatchesAll - 1).times{|time| File.delete(@out.getTempFile(track, time + 2))}

    if @errors.size == 0
      @log.add(_("Every chunk matched %s times :)\n") % [@reqMatchesAll])
    else
      @log.mismatch(track, @trial, @errors.keys, @disc.getFileSize(track), @disc.getLengthSector(track)) # report for later position analysis
      @log.add(_("%s chunk(s) didn't match %s times.\n") % [@errors.length, @reqMatchesAll])
    end
  end

  # Compare if trial_1 matches trial_2, if trial_2 matches trial_3, and so on
  def filesEqual?(track)
    comparesNeeded = @reqMatchesAll - 1
    trial = 1
    success = true

    while comparesNeeded > 0 && success == true
      file1 = @out.getTempFile(track, trial)
      file2 = @out.getTempFile(track, trial + 1)
      success = FileUtils.compare_file(file1, file2)
      trial += 1
      comparesNeeded -= 1
    end

    return success
  end

  # Compare the different sectors now we know the files are not equal
  # The first trial is used as a reference to compare the others
  # Bytes of erronous sectors are kept in memory for future comparisons
  def compareSectors(track)
    files = Array.new
    (1..@reqMatchesAll).each{|trial| files << File.new(@out.getTempFile(track, trial), 'r')}

    comparesNeeded = @reqMatchesAll - 1
    (1..comparesNeeded).each do |trial|
      index = 0
      setFileIndex(files, index)

      while index + BYTES_WAV_CONTAINER < @disc.getFileSize(track)
        if sectorEqual?(files[0], files[trial]) && !@errors.key?(index)
          setFileIndex(files, index) # set back to read again
          @errors[index] = Array.new
          files.each{|file| @errors[index] << file.sysread(BYTES_AUDIO_SECTOR)}
        end
        index += BYTES_AUDIO_SECTOR
      end
    end

    files.each{|file| file.close}
  end

  def setFileIndex(filesArray, index)
    filesArray.each{|file| file.pos = index + BYTES_WAV_CONTAINER}
  end

  def sectorEqual?(file1, file2)
    file1.sysread(BYTES_AUDIO_SECTOR) == file2.sysread(BYTES_AUDIO_SECTOR)
  end

  # When required matches for mismatched sectors are bigger than there are
  # trials to be tested, readErrorPos() just reads the mismatched sectors
  # without analysing them.
  # Wav-containter overhead = 44 bytes.
  # Audio-cd sector = 2352 bytes.

  def readErrorPos(track)
    file = File.new(@out.getTempFile(track, @trial), 'r')
    @errors.keys.sort.each do |start_chunk|
      file.pos = start_chunk + BYTES_WAV_CONTAINER
      @errors[start_chunk] << file.sysread(BYTES_AUDIO_SECTOR)
    end
    file.close

    # Remove the file now we read it. Differences are saved in memory.
    File.delete(@out.getTempFile(track, @trial))

    # Give an update for the trials for later analysis
    @log.mismatch(track, @trial, @errors.keys, @disc.getFileSize(track), @disc.getLengthSector(track))
  end

  # Let the errors 'wave' out. For each sector that isn't unique across
  # different trials, try to find at least @reqMatchesErrors matches. If
  # indeed this amount of matches is found, correct the sector in the
  # reference file (trial 1).

  def correctErrorPos(track)
    file1 = File.new(@out.getTempFile(track, 1), 'r+')
    minimumIndexDiff = @reqMatchesErrors - 1 # index 2 minus index 0 = 3 results

    # Sort the hash keys to prevent jumping forward and backwards in the file
    @errors.keys.sort.each do |key|
      raise "Wrong class for key: #{key.class}" if key.class != Fixnum
      @errors[key].sort!
      @errors[key].uniq.each do |result|
        raise "Wrong class for result: #{result.class}" if result.class != String
        raise "Wrong class for errors[key]: #{@errors[key].class}" if @errors[key].class != Array
        if @errors[key].rindex(result) - @errors[key].index(result) >= minimumIndexDiff
          file1.pos = key
          file1.write(result)
          @errors.delete(key)
        end
      end
    end

    file1.close

    #give an update of the amount of errors and trials
    if @errors.size == 0
      @log.add(_("Error(s) succesfully corrected, %s matches found for each chunk :)\n") % [@reqMatchesErrors])
    else
      @log.mismatch(track, @trial, @errors.keys, @disc.getFileSize(track), @disc.getLengthSector(track)) # report for later position analysis
      @log.add(_("%s chunk(s) didn't match %s times.\n") % [@errors.length, @reqMatchesErrors])
    end
  end

  # add a timeout if a disc takes longer than 30 minutes to rip (this might save the hardware and the disc)
  def cooldownNeeded
    puts "Minutes ripping is #{(Time.now - @timeStarted) / 60}." if @prefs.debug

    if (((Time.now - @timeStarted) / 60) > 30 && @prefs['maxThreads'] != 0)
      @log.add(_("The drive is spinning for more than 30 minutes.\n"))
      @log.add(_("Taking a timeout of 2 minutes to protect the hardware.\n"))
      sleep(120)
      @timeStarted = Time.now # reset time
    end
  end

  def rip(track) # set cdparanoia command + parameters
    cooldownNeeded()

    timeStarted = Time.now

    if @prefs.image
      @log.add(_("Starting to rip CD image, trial \#%s") % [@trial])
    else
      @log.add(_("Starting to rip track %s, trial \#%s") % [track, @trial])
    end

    command = "cdparanoia"

    if @prefs.rippersettings.size != 0
      command += " #{@prefs.rippersettings}"
    end

    command += " [.#{@disc.getStartSector(track)}]-"

    # for the last track tell cdparanoia to rip till end to prevent problems on some drives
    if !@prefs.image && track != @disc.audiotracks
      command += "[.#{@disc.getLengthSector(track) - 1}]"
    end

    # the ported cdparanoia for MacOS misses the -d option, default drive will be used.
    if @disc.multipleDriveSupport ; command += " -d #{@prefs.cdrom}" end

    command += " -O #{@prefs.offset}"
    command += " \"#{@out.getTempFile(track, @trial)}\""
    puts command if @prefs.debug
    @exec.launch(command) if @cancelled == false #Launch the cdparanoia command
    @log.add(" (#{(Time.now - timeStarted).to_i} #{_("seconds")})\n")
  end

  def getDigest(track)
    digest = Digest::MD5.new()
    file = File.open(@out.getTempFile(track, 1), 'r')
    chunksize = 100000
    index = 0
    while (index < @disc.getFileSize(track))
      digest << file.sysread(chunksize)
      index += chunksize
    end
    file.close()
    @log.add(_("MD5 sum: %s\n\n") % [digest.hexdigest])
  end
end
