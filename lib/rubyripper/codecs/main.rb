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

require 'rubyripper/disc/disc'
require 'rubyripper/fileScheme'
require 'rubyripper/metadata/filter/filterTags'
require 'rubyripper/preferences/main'

# build up the command for any specific codec using the configuration
# in each codec file like mp3.rb, vorbis.rb, etcetera. Also provide
# ways to return the replaygain command. Execution is not part of this class.
module Codecs
  class Main
    def initialize(codec, disc=nil, scheme=nil, tags=nil, prefs=nil, metadata=nil)
      @codec = config(codec)
      @disc = disc
      @scheme = scheme
      @tags = tags ? tags : Metadata::FilterTags.new(@disc.metadata)
      @md = metadata ? metadata : @disc.metadata
      @prefs = prefs ? prefs : Preferences::Main.instance()
    end
     
    # to replaygain a single track
    def replaygain(track)
      @codec.replaygain(track) % [output(track)]
    end
  
    # to replaygain a complete album
    def replaygainAlbum()
      @codec.replaygainAlbum() % [File.join(dir(), '*.' + @codec.extension)]
    end
  
    # return the command for the track and codec
    def command(track)
      command = Array.new()
      @codec.sequence.each do |part|
        command << case part
          when :binary then addBinary()
          when :prefs then addPreference()
          when :tags then addTags(track)
          when :input then addInput(track)
          when :output then addOutput(track)
        end
      end
      command.delete('')
      command.join(' ')
    end
    
    # some codecs set the tags after the encoding (for example nero AAC)
    def setTagsAfterEncoding(track)
      command = Array.new()
      if @codec.respond_to?(:sequenceTags)
        @codec.sequenceTags.each do |part|
          command << case part
            when :binary then addTagBinary()
            when :input then addTagInput(track)
            when :tags then addTags(track)
          end
        end
      end
      command.delete('')
      command.join(' ')
    end
  
    private
  
    # get the configuration and return the specific codec object
    def config(codec)
      require "rubyripper/codecs/#{codec}"
      Codecs.const_get(codec.capitalize).new
    end
    
    def addBinary
      @codec.binary
    end
    
    def addPreference
      prefs = @prefs.send("settings" + @codec.name.capitalize)
      prefs = @codec.default if prefs == nil || prefs.strip().empty?
      prefs.strip()
    end
    
    def addTags(track)
      result = Array.new
      @codec.tags.each do |key, value|
        tag = case key
          when :artist then add(value, @tags.trackArtist(track))
          when :album then add(value, @tags.album)
          when :genre then add(value, @tags.genre)
          when :year then add(value, @tags.year)
          when :albumArtist then add(value, @tags.artist) if @md.various?
          when :discId then add(value, "\"#{@disc.freedbDiscid}\"") if @disc.freedbDiscid
          when :discNumber then add(value, @md.discNumber) if @md.discNumber
          when :encoder then add(value, "\"Rubyripper #{$rr_version}\"")
          when :cuesheet then add(value, "\"#{@scheme.getCueFile(@codec.name)}\"") if @prefs.createCue
          when :trackname then add(value, @tags.trackname(track))
          when :tracknumber then add(value, "#{track}")
          when :tracktotal then add(value, "#{@disc.audiotracks}")
          when :tracknumberTotal then add(value, "#{track}/#{@disc.audiotracks}")
        end
        result << tag unless tag.nil? || tag.strip().empty?
      end
      result.join(" ")
    end
    
    def addInput(track)
      if @codec.respond_to?(:inputEncodingTag)
        add(@codec.inputEncodingTag, input(track))
      else
        input(track)
      end
    end
    
    def addOutput(track)
      if @codec.respond_to?(:outputEncodingTag)
        add(@codec.outputEncodingTag, output(track))
      else
        output(track)
      end
    end
    
    def addTagBinary
      @codec.tagBinary
    end
    
    def addTagInput(track)
      output(track)
    end
    
    # return the input file for encoding
    def input(track)
      "\"#{@scheme.getTempFile(track)}\""
    end
  
    # return the output file for encoding
    def output(track)
      "\"#{@scheme.getFile(track, @codec.name)}\""
    end
  
    # if tag ends with equal sign dont use a space separator
    def add(tag, value)
      separator = tag[-1] == '=' ? '' : ' '
      value.empty? ? '' : tag + separator + value
    end
  
    def dir()
      "\"#{@scheme.getDir(@codec.name)}\""
    end
  end
end

