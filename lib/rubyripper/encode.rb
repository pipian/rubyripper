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

# TODO make one general Encode class, subclass each codec
# TODO move the managing of threads to a separate class
# TODO move the commands to fireCommand class
# The Encode class is responsible for managing the diverse codecs.

require 'thread' # for the sized queue object
require 'monitor' # for the monitor object
require 'fileutils' # for the fileutils object

require 'rubyripper/system/dependency'
require 'rubyripper/system/execute'
require 'rubyripper/preferences/main'

class Encode
  attr_writer :cancelled

  def initialize(outputFile, log, trackSelection, disc, deps=nil, exec=nil, prefs=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @out = outputFile
    @log = log
    @trackSelection = trackSelection
    @disc = disc
    @md = disc.metadata
    @deps = deps ? deps : Dependency.instance
    @exec = exec ? exec : Execute.new()
    @cancelled = false
    @progress = 0.0
    @threads = []
    @queue = SizedQueue.new(@prefs.maxThreads) if @prefs.maxThreads != 0
    @lock = Monitor.new

    # Set the charset environment variable to UTF-8. Oggenc needs this.
    # Perhaps others need it as well.
    ENV['CHARSET'] = "UTF-8"

    @countCodecs = 0 # number of codecs
    ['flac','vorbis','mp3','wav','other'].each do |codec|
      @countCodecs += 1 if @prefs.send(codec)
    end

    # all encoding tasks are saved here, to determine when to delete a wav
    @tasks = Hash.new
    @trackSelection.each{|track| @tasks[track] = @countCodecs}
  end

  # is called when a track is ripped succesfully
  def addTrack(track)
    if normalize(track)
      startEncoding(track)
    end
  end

  # encode track when normalize is finished
  def startEncoding(track)
    # mark the progress bar as being started
    @log.updateEncodingProgress() if track == @trackSelection[0]
    ['flac', 'vorbis', 'mp3', 'wav', 'other'].each do |codec|
      if @prefs.send(codec) && @cancelled == false
        if @prefs.maxThreads == 0
          encodeTrack(track,codec)
        else
          puts "Adding track #{track} (#{codec}) to the queue.." if @prefs.debug
          @queue << 1 # add a value to the queue, if full wait here.
          @threads << Thread.new do
            encodeTrack(track,codec)
            puts "Removing track #{track} (#{codec}) from the queue.." if @prefs.debug
            @queue.shift() # move up in the queue to the first waiter
          end
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
  def normalize(track)
    continue = true
    if @prefs.normalizer != 'normalize'
    elsif !@deps.installed?('normalize')
      puts "WARNING: normalize is not installed on your system!"
    elsif @prefs.gain == 'album' && @trackSelection[-1] == track
      command = "normalize -b \"#{File.join(@out.getTempDir(),'*.wav')}\""
      @exec.launch(command)
      # now the wavs are altered, the encoding can start
      @trackSelection.each{|track| startEncoding(track)}
      continue = false
    elsif @prefs.gain == 'track'
      command = "normalize \"#{@out.getTempFile(track, 1)}\""
      @exec.launch(command)
    end
    return continue
  end

  # call the specific codec function for the track
  def encodeTrack(track, codec)
    if codec == 'flac' ; doFlac(track)
    elsif codec == 'vorbis' ; doVorbis(track)
    elsif codec == 'mp3' ; doMp3(track)
    elsif codec == 'wav' ; doWav(track)
    elsif codec == 'other' && @prefs.settingsOther != nil ; doOther(track)
    end

    @lock.synchronize do
      File.delete(@out.getTempFile(track, 1)) if (@tasks[track] -= 1) == 0
      @log.updateEncodingProgress(track, @countCodecs)
    end
  end

  def replaygain(filename, codec, track)
    if @prefs.normalizer == "replaygain"
      command = ''
      if @prefs.gain == "album" && @trackSelection[-1] == track || @prefs.gain =="track"
        if codec == 'flac' && installed('metaflac')
          command = "metaflac --add-replay-gain \"#{if @prefs.gain =="track" ; filename else File.dirname(filename) + "\"/*.flac" end}"
        elsif codec == 'vorbis' && installed('vorbisgain')
          command = "vorbisgain #{if @prefs.gain =="track" ; "\"" + filename + "\"" else "-a \"" + File.dirname(filename) + "\"/*.ogg" end}"
        elsif codec == 'mp3' && installed('mp3gain') && @prefs.gainTagsOnly
          command = "mp3gain -c #{if @prefs.gain =="track" ; "\"" + filename + "\"" else "\"" + File.dirname(filename) + "\"/*.mp3" end}"
        elsif codec == 'mp3' && installed('mp3gain') && !@prefs.gainTagsOnly
          command = "mp3gain -c #{if @prefs.gain =="track" ; "-r \"" + filename + "\"" else "-a \"" + File.dirname(filename) + "\"/*.mp3" end}"
        elsif codec == 'wav' && installed('wavegain')
          command = "wavegain #{if @prefs.gain =="track" ; "\"" + filename +"\"" else "-a \"" + File.dirname(filename) + "\"/*.wav" end}"
        end
      end
      @exec.launch(command) if command != ''
    end
  end

  def doFlac(track)
    filename = @out.getFile(track, 'flac')
    @prefs.settingsFlac ||= '--best'
    flac(filename, track)
    replaygain(filename, 'flac', track)
  end

  def doVorbis(track)
    filename = @out.getFile(track, 'vorbis')
    @prefs.settingsVorbis ||= '-q 6'
    vorbis(filename, track)
    replaygain(filename, 'vorbis', track)
  end

  def doMp3(track)
    @possible_lame_tags = ['A CAPPELLA', 'ACID', 'ACID JAZZ', 'ACID PUNK', 'ACOUSTIC', 'ALTERNATIVE', 'ALT. ROCK', 'AMBIENT', 'ANIME', 'AVANTGARDE', \
'BALLAD', 'BASS', 'BEAT', 'BEBOB', 'BIG BAND', 'BLACK METAL', 'BLUEGRASS', 'BLUES', 'BOOTY BASS', 'BRITPOP', 'CABARET', 'CELTIC', 'CHAMBER MUSIC', 'CHANSON', \
'CHORUS', 'CHRISTIAN GANGSTA RAP', 'CHRISTIAN RAP', 'CHRISTIAN ROCK', 'CLASSICAL', 'CLASSIC ROCK', 'CLUB', 'CLUB-HOUSE', 'COMEDY', 'CONTEMPORARY CHRISTIAN', \
'COUNTRY', 'CROSSOVER', 'CULT', 'DANCE', 'DANCE HALL', 'DARKWAVE', 'DEATH METAL', 'DISCO', 'DREAM', 'DRUM & BASS', 'DRUM SOLO', 'DUET', 'EASY LISTENING', \
'ELECTRONIC', 'ETHNIC', 'EURODANCE', 'EURO-HOUSE', 'EURO-TECHNO', 'FAST-FUSION', 'FOLK', 'FOLKLORE', 'FOLK/ROCK', 'FREESTYLE', 'FUNK', 'FUSION', 'GAME', \
'GANGSTA RAP', 'GOA', 'GOSPEL', 'GOTHIC', 'GOTHIC ROCK', 'GRUNGE', 'HARDCORE', 'HARD ROCK', 'HEAVY METAL', 'HIP-HOP', 'HOUSE', 'HUMOUR', 'INDIE', 'INDUSTRIAL', \
'INSTRUMENTAL', 'INSTRUMENTAL POP', 'INSTRUMENTAL ROCK', 'JAZZ', 'JAZZ+FUNK', 'JPOP', 'JUNGLE', 'LATIN', 'LO-FI', 'MEDITATIVE', 'MERENGUE', 'METAL', 'MUSICAL', \
'NATIONAL FOLK', 'NATIVE AMERICAN', 'NEGERPUNK', 'NEW AGE', 'NEW WAVE', 'NOISE', 'OLDIES', 'OPERA', 'OTHER', 'POLKA', 'POLSK PUNK', 'POP', 'POP-FOLK', 'POP/FUNK', \
'PORN GROOVE', 'POWER BALLAD', 'PRANKS', 'PRIMUS', 'PROGRESSIVE ROCK', 'PSYCHEDELIC', 'PSYCHEDELIC ROCK', 'PUNK', 'PUNK ROCK', 'RAP', 'RAVE', 'R&B', 'REGGAE', \
'RETRO', 'REVIVAL', 'RHYTHMIC SOUL', 'ROCK', 'ROCK & ROLL', 'SALSA', 'SAMBA', 'SATIRE', 'SHOWTUNES', 'SKA', 'SLOW JAM', 'SLOW ROCK', 'SONATA', 'SOUL', 'SOUND CLIP', \
'SOUNDTRACK', 'SOUTHERN ROCK', 'SPACE', 'SPEECH', 'SWING', 'SYMPHONIC ROCK', 'SYMPHONY', 'SYNTHPOP', 'TANGO', 'TECHNO', 'TECHNO-INDUSTRIAL', 'TERROR', 'THRASH METAL', \
'TOP 40', 'TRAILER', 'TRANCE', 'TRIBAL', 'TRIP-HOP', 'VOCAL']
    filename = @out.getFile(track, 'mp3')
    @prefs.settingsMp3 ||= "--preset fast standard"

    # lame versions before 3.98 didn't support other genre tags than the
    # ones defined above, so change it to 'other' to prevent crashes
    lameVersion = `lame --version`[20,4].split('.') # for example [3, 98]
    if (lameVersion[0] == '3' && lameVersion[1].to_i < 98 &&
    !@possible_lame_tags.include?(@out.genre.upcase))
      genre = 'other'
    else
      genre = @out.genre
    end

    mp3(filename, genre, track)
    replaygain(filename, 'mp3', track)
  end

  def doWav(track)
    filename = @out.getFile(track, 'wav')
    wav(filename, track)
    replaygain(filename, 'wav', track)
  end

  def doOther(track)
    filename = @out.getFile(track, 'other')
    command = @prefs.settingsOther.dup

    command.force_encoding("UTF-8") if command.respond_to?("force_encoding")
    command.gsub!('%n', sprintf("%02d", track)) if track != "image"
    command.gsub!('%f', 'other')

    if @out.getVarArtist(track) != ''
      command.gsub!('%a', @out.getVarArtist(track))
      command.gsub!('%va', @out.artist)
    else
      command.gsub!('%a', @out.artist)
    end

    command.gsub!('%b', @out.album)
    command.gsub!('%g', @out.genre)
    command.gsub!('%y', @out.year)
    command.gsub!('%t', @out.getTrackname(track))
    command.gsub!('%i', @out.getTempFile(track, 1))
    command.gsub!('%o', @out.getFile(track, 'other'))
    checkCommand(command, track, 'other')
  end

  def flac(filename, track)
    tags = String.new
    tags.force_encoding("UTF-8") if tags.respond_to?("force_encoding")
    tags += "--tag ALBUM=\"#{@out.album}\" "
    tags += "--tag DATE=\"#{@out.year}\" "
    tags += "--tag GENRE=\"#{@out.genre}\" "
    tags += "--tag DISCID=\"#{@disc.freedbDiscid}\" "
    tags += "--tag DISCNUMBER=\"#{@md.discNumber}\" " if @md.discNumber

    # Handle tags for single file images differently
    if @prefs.image
      tags += "--tag ARTIST=\"#{@out.artist}\" " #artist is always artist
      if @prefs.createCue # embed the cuesheet
        tags += "--cuesheet=\"#{@out.getCueFile('flac')}\" "
      end
    else # Handle tags for var artist discs differently
      if @out.getVarArtist(track) != ''
        tags += "--tag ARTIST=\"#{@out.getVarArtist(track)}\" "
        tags += "--tag \"ALBUM ARTIST\"=\"#{@out.artist}\" "
      else
        tags += "--tag ARTIST=\"#{@out.artist}\" "
      end
      tags += "--tag TITLE=\"#{@out.getTrackname(track)}\" "
      tags += "--tag TRACKNUMBER=#{track} "
      tags += "--tag TRACKTOTAL=#{@disc.audiotracks} "
    end

    command = String.new
    command.force_encoding("UTF-8") if command.respond_to?("force_encoding")
    command +="flac #{@prefs.settingsFlac} -o \"#{filename}\" #{tags}\
\"#{@out.getTempFile(track, 1)}\""

    checkCommand(command, track, 'flac')
  end

  def vorbis(filename, track)
    tags = String.new
    tags.force_encoding("UTF-8") if tags.respond_to?("force_encoding")
    tags += "-c ALBUM=\"#{@out.album}\" "
    tags += "-c DATE=\"#{@out.year}\" "
    tags += "-c GENRE=\"#{@out.genre}\" "
    tags += "-c DISCID=\"#{@disc.freedbDiscid}\" "
    tags += "-c DISCNUMBER=\"#{@md.discNumber}\" " if @md.discNumber

    # Handle tags for single file images differently
    if @prefs.image
      tags += "-c ARTIST=\"#{@out.artist}\" "
    else # Handle tags for var artist discs differently
      if @out.getVarArtist(track) != ''
        tags += "-c ARTIST=\"#{@out.getVarArtist(track)}\" "
        tags += "-c \"ALBUM ARTIST\"=\"#{@out.artist}\" "
      else
        tags += "-c ARTIST=\"#{@out.artist}\" "
      end
      tags += "-c TITLE=\"#{@out.getTrackname(track)}\" "
      tags += "-c TRACKNUMBER=#{track} "
      tags += "-c TRACKTOTAL=#{@disc.audiotracks}"
    end

    command = String.new
    command.force_encoding("UTF-8") if command.respond_to?("force_encoding")
    command += "oggenc -o \"#{filename}\" #{@prefs.settingsVorbis} \
#{tags} \"#{@out.getTempFile(track, 1)}\""
    command += " 2>&1" unless @prefs.verbose

    checkCommand(command, track, 'vorbis')
  end

  def mp3(filename, genre, track)
    tags = String.new
    tags.force_encoding("UTF-8") if tags.respond_to?("force_encoding")
    tags += "--tl \"#{@out.album}\" "
    tags += "--ty \"#{@out.year}\" "
    tags += "--tg \"#{@out.genre}\" "
    tags += "--tv TXXX=DISCID=\"#{@disc.freedbDiscid}\" "
    tags += "--tv TPOS=\"#{@md.discNumber}\" " if @md.discNumber

    # Handle tags for single file images differently
    if @prefs.image
      tags += "--ta \"#{@out.artist}\" "
    else # Handle tags for var artist discs differently
      if @out.getVarArtist(track) != ''
        tags += "--ta \"#{@out.getVarArtist(track)}\" "
        tags += "--tv \"ALBUM ARTIST\"=\"#{@out.artist}\" "
      else
        tags += "--ta \"#{@out.artist}\" "
      end
      tags += "--tt \"#{@out.getTrackname(track)}\" "
      tags += "--tn #{track}/#{@disc.audiotracks} "
    end

    # set UTF-8 tags (not the filename) to latin because of a lame bug.
    begin
      require 'iconv'
      tags = Iconv.conv("ISO-8859-1", "UTF-8", tags)
    rescue
      puts "couldn't convert to ISO-8859-1 succesfully"
    end

    # combining two encoding sets in binary mode, only needed for ruby >=1.9
    command = String.new
    inputWavFile = @out.getTempFile(track, 1)
    if command.respond_to?("force_encoding")
      command.force_encoding("ASCII-8BIT")
      tags.force_encoding("ASCII-8BIT")
      inputWavFile.force_encoding("ASCII-8BIT")
      filename.force_encoding("ASCII-8BIT")
    end

    command += "lame #{@prefs.settingsMp3} #{tags}\"\
#{inputWavFile}\" \"#{filename}\""
    command += " 2>&1" unless @prefs.verbose

    checkCommand(command, track, 'mp3')
  end

  def wav(filename, track)
    begin
      FileUtils.cp(@out.getTempFile(track, 1), filename)
    rescue
      puts "Warning: wav file #{@out.getTempFile(track,1)} not found!"
      puts "If this is not the case, you might have a shortage of disk space.."
    end
  end

  def checkCommand(command, track, codec)
    puts "command = #{command}" if @prefs.debug

    exec = IO.popen("nice -n 6 #{command}") #execute command
    exec.readlines() #get all the output

    if Process.waitpid2(exec.pid)[1].exitstatus != 0
      @log.add(_("WARNING: Encoding to %s exited with an error with track %s!\n") % [codec, track])
      @log.encodingErrors = true
    end
  end
end
