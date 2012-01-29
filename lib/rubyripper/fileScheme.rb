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

# FileScheme is a helpclass that defines all the names of the directories,
# filenames and tags. It filters out special characters that are not
# well supported in the different platforms. It also offers some help
# functions to create the output dirs and to get a preview of the output.
# Since all the info is here, also create the playlist files. The cuesheets
# are also made with help of the Cuesheet class.
# Output is initialized as soon as the player pushes Rip Now!

require 'rubyripper/preferences/main'
require 'fileutils'

class FileScheme
attr_reader :status, :artist, :album, :year, :genre, :dir

  # prefs = prefs object
  # disc = disc object
  # trackSelection = array with tracknumbers to rip
  def initialize(disc, trackSelection, prefs=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @disc = disc
    @md = disc.metadata
    @trackSelection = trackSelection

    @codecs = ['flac', 'vorbis', 'mp3', 'wav', 'other']

    # the output of the dirs for each codec, and files for each tracknumber + codec.
    @dir = Hash.new
    @file = Hash.new
    @image = Hash.new

    # the metadata made ready for tagging usage
    @artist = String.new
    @album = String.new
    @year = String.new
    @genre = String.new
    @tracklist = Hash.new
    @varArtists = Hash.new
    @otherExtension = String.new
  end
  
  def prepare
    splitDirFile()
    checkNames()
    setDirectory()
  end
  
  # (re)attempt creation of the dirs, when succesfull create the filenames
  def createDirs
    createDir()
    createTempDir()
    setFreedb()
    findExtensionOther()
    setFileNames()
    createFiles()
  end

  # split the filescheme into a dir and a file
  def splitDirFile
    if @prefs.image
      fileScheme = @prefs.namingImage
    elsif @md.various?
      fileScheme = @prefs.namingVarious
    else
      fileScheme = @prefs.namingNormal
    end

    # the basedir is added later on, since we don't want to change it
    @dirName, @fileName = File.split(fileScheme)
  end

# Do a few sanity checks
# 1) Remove dot(s) from the albumname when it's the start of a directory,
# otherwise they're hidden files in linux.
# 2) Check if %va exists in filescheme for normal artists
# 3) Check if %n exists in single file rip scheme
# 4) Check if %va exists in single file rip scheme
# 5) Check if %t exists in single file rip scheme

  def checkNames
    if @dirName.include?("/%b") && @md.album[0,1] == '.'
      @dirName.sub!(/\.*/, '')
    end

    if !@md.various? && @fileName.include?('%va')
      @fileName.gsub!('%va', '')
      puts "Warning: '%va' in the filescheme for normal cd's makes no sense!"
      puts "This is automatically removed"
    end

    if @prefs.image
      if @fileName.include?('%n')
        @fileName.gsub!('%n', '')
        puts "Warning: '%n' in the filescheme for image rips makes no sense!"
        puts "This is automatically removed"
      end

      if @fileName.include?('%va')
        @fileName.gsub!('%va', '')
        puts "Warning: '%va' in the filescheme for image rips makes no sense!"
        puts "This is automatically removed"
      end

      if @fileName.include?('%t')
        @fileName.gsub!('%t', '')
        puts "Warning: '%t' in the filescheme for image rips makes no sense!"
        puts "This is automatically removed"
      end
    end
  end

  # fill the @dir variable with all output dirs
  def setDirectory
    @codecs.each{|codec| @dir[codec] = giveDir(codec) if @prefs.send(codec)}
  end

  # determine the output dir
  def giveDir(codec)
    dirName = @dirName.dup

    # no forward slashes allowed in dir names
    @artistFile = @md.artist.gsub('/', '')
    @albumFile = @md.album.gsub('/', '')

    # do not allow multiple directories for various artists
    {'%a' => @artistFile, '%b' => @albumFile, '%f' => codec, '%g' => @md.genre,
    '%y' => @md.year, '%va' => @artistFile}.each do |key, value|
      if value.nil?
        dirName.gsub!(key, '')
      else
        dirName.gsub!(key, value)
      end
    end

    if @md.discNumber
      dirName = File.join(dirName, "CD #{sprintf("%02d", @md.discNumber)}")
    end

    dirName = fileFilter(dirName, true)
    return File.expand_path(File.join(@prefs.basedir, dirName))
  end

  def findExtensionOther
    if @prefs.other
      @prefs.settingsOther =~ /"%o".\S+/ # ruby magic, match %o.+ any characters that are not like spaces
      @otherExtension = $&[4..-1]
      @prefs.settingsOther.gsub!(@otherExtension, '') # remove any references to the ext in the settings
    end
  end

  # create playlist + cuesheet files
  def createFiles
    @codecs.each do |codec|
      if @prefs.send(codec) && @prefs.playlist && !@prefs.image
        createPlaylist(codec)
      end
    end
  end

  # create the output dirs
  def createDir
    @dir.values.each{|dir| FileUtils.mkdir_p(dir)}
  end

  # create the temp dir
  def createTempDir
    if not File.directory?(getTempDir)
      FileUtils.mkdir_p(getTempDir)
    end
  end

  # fill the @file variable, so we have for example @file['flac'][1]
  def setFileNames
    @codecs.each do |codec|
      if @prefs.send(codec)
        @file[codec] = Hash.new
        if @prefs.image
          @image[codec] = giveFileName(codec)
        else
          @trackSelection.each do |track|
            @file[codec][track] = giveFileName(codec, track)
          end
        end
      end
    end

    #if no hidden track is detected, getStartSector will return false
    setHiddenTrack() if @disc.getStartSector(0)
  end

  # give the filename for given codec and track
  def giveFileName(codec, track=0)
    file = @fileName.dup

    # the artist should always refer to the artist that is valid for the track
    if getVarArtist(track + 1) == '' ; artist = @md.artist ; varArtist = ''
    else artist = getVarArtist(track + 1) ; varArtist = @md.artist end

    {'%a' => artist, '%b' => @md.album, '%f' => codec, '%g' => @md.genre,
    '%y' => @md.year, '%n' => sprintf("%02d", track), '%va' => varArtist,
    '%t' => getTrackname(track)}.each do |key, value|
      if value.nil?
        file.gsub!(key, '')
      else
        file.gsub!(key, value)
      end
    end

    # other codec has the extension already in the command
    if codec == 'flac' ; file += '.flac'
    elsif codec == 'vorbis' ; file += '.ogg'
    elsif codec == 'mp3' ; file += '.mp3'
    elsif codec == 'wav' ; file += '.wav'
    elsif codec == 'other' ; file += @otherExtension
    end

    filename = fileFilter(file)
    puts filename if @prefs.debug
    return filename
  end

  # Fill the metadata, made ready for tagging
  def setFreedb
    @artist = tagFilter(@md.artist)
    @album = tagFilter(@md.album)
    @genre = tagFilter(@md.genre)
    @year = tagFilter(@md.year)
    (1..@disc.audiotracks).each do |track|
      @tracklist[track] = tagFilter(@md.tracklist[track])
    end
    if @md.various?
      (1..@disc.audiotracks).each do |track|
        @varArtists[track] = tagFilter(@md.varArtists[track])
      end
    end
  end

  # Fill the metadata for the hidden track
  def setHiddenTrack
    @tracklist[0] = tagFilter(_("Hidden Track").dup)
    @varArtists[0] = tagFilter(_("Unknown Artist").dup) if not @md.varArtists.empty?
    @codecs.each{|codec| @file[codec][0] = giveFileName(codec, 0) if @prefs.send(codec)}
  end

  # characters that will be changed for filenames (monkeyproof for FAT32)
  def fileFilter(var, isDir=false)
    if not isDir
      var.gsub!('/', '') #no slashes allowed in filenames
    end
    var.gsub!('$', 's') #no dollars allowed
    var.gsub!(':', '') #no colons allowed in FAT
    var.gsub!('*', '') #no asterix allowed in FAT
    var.gsub!('?', '') #no question mark allowed in FAT
    var.gsub!('<', '') #no smaller than allowed in FAT
    var.gsub!('>', '') #no greater than allowed in FAT
    var.gsub!('|', '') #no pipe allowed in FAT
    var.gsub!('\\', '') #the \\ means a normal \
    var.gsub!('"', '')

    allFilter(var)

    var.gsub!(" ", "_") if @prefs.noSpaces
    var.downcase! if @prefs.noCapitals
    return var.strip
  end

  #characters that will be changed for tags
  def tagFilter(var)
    allFilter(var)

    #Add a slash before the double quote chars,
    #otherwise the shell will complain
    var.gsub!('"', '\"')
    return var.strip
  end

  # characters that will be changed for tags and filenames
  def allFilter(var)
    var.gsub!('`', "'")

    # replace any underscores with spaces, some freedb info got
    # underscores instead of spaces
    var.gsub!('_', ' ') unless @prefs.noSpaces

    if var.respond_to?(:encoding)
      # prepare for byte substitutions
      enc = var.encoding
      var.force_encoding("ASCII-8BIT")
    end

    # replace utf-8 single quotes with latin single quote
    var.gsub!(/\342\200\230|\342\200\231/, "'")

    # replace utf-8 double quotes with latin double quote
    var.gsub!(/\342\200\234|\342\200\235/, '"')

    if var.respond_to?(:encoding)
      # restore the old encoding
      var.force_encoding(enc)
    end
  end

  # add the first free number as a postfix to the output dir
  def postfixDir
    postfix = 1
    @dir.values.each do |dir|
      while File.directory?(dir + "\##{postfix}")
        postfix += 1
      end
    end
    @dir.keys.each{|key| @dir[key] = @dir[key] += "\##{postfix}"}
  end

  # remove the existing dir, starting with the files in it
  def overwriteDir
    @dir.values.each{|dir| cleanDir(dir) if File.directory?(dir)}
  end

    # clean a directory, starting with the files in it
  def cleanDir(dir)
    Dir.foreach(dir) do |file|
      if File.directory?(file) && file[0..0] != '.' ; cleanDir(File.join(dir, file)) end
      filename = File.join(dir, file)
      File.delete(filename) if File.file?(filename)
    end
    Dir.delete(dir)
  end

  # create Playlist for each codec
  def createPlaylist(codec)
    playlist = File.new(File.join(@dir[codec],
      "#{@artistFile} - #{@albumFile} (#{codec}).m3u"), 'w')

    @trackSelection.each{|track| playlist.puts @file[codec][track]}
    playlist.close
  end

  # clean temporary Dir (when finished)
  def cleanTempDir
    cleanDir(getTempDir()) if File.directory?(getTempDir())
  end

  # return the first directory (for the summary)
  def getDir
    return @dir.values[0]
  end

  # return the full filename of the track (starting with 1) or image
  def getFile(track=false, codec)
    if @prefs.image
      return File.join(@dir[codec], @image[codec])
    else
      return File.join(@dir[codec], @file[codec][track])
    end
  end

  # return the toc file of AdvancedToc class
  def getTocFile
    return File.join(getTempDir(), "#{@artistFile} - #{@albumFile}.toc")
  end

  # return the full filename of the log
  def getLogFile(codec)
    return File.join(@dir[codec], 'ripping.log')
  end

  # return the full filename of the cuesheet
  def getCueFile(codec)
    return File.join(@dir[codec], "#{@artistFile} - #{@albumFile} (#{codec}).cue")
  end

  def getTempFile(track=false, trial)
    if @prefs.image
      return File.join(getTempDir(), "image_#{trial}.wav")
    else
      return File.join(getTempDir(), "track#{track}_#{trial}.wav")
    end
  end

  #return the temporary dir
  def getTempDir
    return File.join(File.dirname(@dir.values[0]), "temp_#{File.basename(@prefs.cdrom)}/")
  end

  #return the trackname for the metadata
  def getTrackname(track)
    if @tracklist[track] == nil
      return ''
    else
      return @tracklist[track]
    end
  end

  #return the artist for the metadata
  def getVarArtist(track)
    if @varArtists[track] == nil
      return ''
    else
      return @varArtists[track]
    end
  end
end
