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

# helper class to handle the http traffic
require 'rubyripper/musicbrainz/musicbrainzWebService'
require 'rubyripper/preferences/main'

#for parsing xml
require 'rexml/document'
#for CGI.parse
require 'cgi'

# This class tries to implement the MusicBrainz XML Web Service 2 protocol
# (specifically, release lookups)
# See http://musicbrainz.org/doc/XML_Web_Service/Version_2 for specs

class GetMusicBrainzRelease
  attr_reader :status, :musicbrainzRelease, :choices

  MMD_NAMESPACE = 'http://musicbrainz.org/ns/mmd-2.0#'

  def initialize(server=nil, prefs=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @server = server ? server : MusicBrainzWebService.new()
  end

  # handle the initial connection with the MusicBrainz server
  def queryDisc(musicbrainzLookupPath)
    @musicbrainzLookupPath = musicbrainzLookupPath
    analyzeQueryResult(queryMusicBrainzForMatches())
  end

  # choose number in the array [0-XX] which result you want to return
  def choose(number)
    if @choices.nil?
      @status = 'noChoices'
    elsif @choices[number].nil?
      @status = "choiceNotValid: #{number}"
    else
      # simulate having found a single record in a query
      oneReleaseFound(@choices[number])
    end
  end

private

  # Query the MusicBrainz web service for available matches.
  # There can be none, one or multiple hits, depending on the response.
  def queryMusicBrainzForMatches()
    uri = URI::parse(File::expand_path(@musicbrainzLookupPath, @server.path))

    # Add necessary inclusions for proper parsing.
    query = CGI.parse(uri.query)
    if query['inc'][-1].nil?
      inclusions = []
    else
      inclusions = query['inc'][-1].split(' ')
    end
    inclusions |= ['artists', 'recordings', 'artist-credits']
    if @prefs.useEarliestDate
      inclusions |= ['release-groups']
    end
    if query['inc'][-1].nil?
      query['inc'] = [inclusions.join(' ')]
    else
      query['inc'][-1] = inclusions.join(' ')
    end
    new_query = String.new
    query.each do |key,values|
      values.each do |value|
        if value.nil?
          new_query << "#{key}"
        else
          value = CGI.escape(value)
          new_query << "#{key}=#{value}"
        end
        new_query << "&"
      end
    end
    uri.query = new_query[0..-2]

    # Need to parse the XML response
    return REXML::Document.new(@server.get(uri.to_s))
  end

  # analyze the reponse code and assign neccesary action
  def analyzeQueryResult(reply)
    # What's in an XML response?
    if reply.root.name == 'error'
      noReleasesFound()
    else
      releases = REXML::XPath::match(reply, '//metadata/disc/release-list/release', {''=>MMD_NAMESPACE})

      case releases.length
      when 0 ; noReleasesFound()
      when 1 ; oneReleaseFound(releases[0])
      else ; multipleReleasesFound(releases)
      end
    end
  end

  # in case no records are found
  def noReleasesFound() ; @status = "noMatches" ; end

  # in case a single release is found
  def oneReleaseFound(release)
    @musicbrainzRelease = release
    @status = 'ok'
  end

  # in case multiple releases are found, intelligently choose one
  # release in a release group
  def multipleReleasesFound(releases)
    # Two ways to filter...
    filterByCountry = (@prefs.preferMusicBrainzCountries == '') ? :never : Hash.new {|h,k| h[k] = Set.new}
    filterByDate = (@prefs.preferMusicBrainzDate == 'no') ? :never : Hash.new {|h,k| h[k] = Set.new}

    # Group releases by the attributes we prefer and prep the preference map
    betterThan = {}
    worseThan = {}
    releasesById = {}
    releases.each do |release|
      betterThan[release.attribute('id')] = 0
      worseThan[release.attribute('id')] = 0
      releasesById[release.attribute('id')] = release
      if filterByCountry != :never
        if release.elements['date'].length > 0
          filterByCountry[release.elements['country'].text] << release.attribute('id')
        else
          filterByCountry[nil] << release.attribute('id')
        end
      end
      if filterByDate != :never
        if release.elements['date'].length > 0
          filterByDate[release.elements['date'].text] << release.attribute('id')
        else
          filterByDate[nil] << release.attribute('id')
        end
      end
    end

    # Build the graph of preferences
    if filterByCountry != :never
      # Releases with no country are not better or worse than any other.
      filterByCountry.delete(nil)
      @prefs.preferMusicBrainzCountries.split(',').each do |country|
        # Each subsequent country is less preferred than the previous.
        releases = filterByCountry.delete(country)
        if not releases.nil?
          releases.each do |release|
            filterByCountry.values.each do |otherReleases|
              otherReleases.each do |otherRelease|
                betterThan[otherRelease] += 1
                worseThan[release] += 1
              end
            end
          end
        end
      end
    end
    if filterByDate != :never
      # Releases with no date are not better or worse than any other.
      filterByDate.delete(nil)
      dates = filterByDate.keys
      # Dates should be sorted by our preference, such that each
      # subsequent date is less preferred than the previous, and we
      # assume that less-specific dates are always worse.
      case @prefs.preferMusicBrainzDate
      when 'earlier' then
        dates.sort! do |x,y|
          if x == y then 0
          elsif x.start_with?(y) then 1
          elsif y.start_with?(x) then -1
          else x <=> y
          end
        end
      when 'later' then
        dates.sort! do |x,y|
          if x == y then 0
          elsif x.start_with?(y) then 1
          elsif y.start_with?(x) then -1
          else y <=> x
          end
        end
      end
      dates.each do |date|
        filterByDate.delete(date).each do |release|
          filterByDate.values.each do |otherReleases|
            otherReleases.each do |otherRelease|
              betterThan[otherRelease] += 1
              worseThan[release] += 1
            end
          end
        end
      end
    end

    # Now we can do some scoring.

    # Get the releases with the MOST releases worse than them.
    numberWorseThan = Hash.new {|h,k| h[k] = Set.new}
    worseThan.each do |release, worseReleaseCount|
      numberWorseThan[worseReleaseCount] << release
    end
    bestScores = numberWorseThan.keys.sort {|x,y| y <=> x}
    @choices = numberWorseThan[bestScores.first].to_a

    if @choices.length > 1
      # Of those releases, get the releases with the FEWEST releases
      # better than them.
      numberBetterThan = Hash.new {|h,k| h[k] = Set.new}
      @choices.each do |release|
        numberBetterThan[betterThan[release]] << release
      end
      bestScores = numberBetterThan.keys.sort
      @choices = numberBetterThan[bestScores.first].to_a
    end

    # Map back to release objects...
    @choices = @choices.collect {|choice| releasesById[choice]}

    # simulate one release found if we were able to successfully
    # whittle down the releases.
    if @choices.length == 1
      oneReleaseFound(@choices[0])
    else
      @status = 'multipleRecords'
    end
  end
end


#	# save it locally for later use TODO
#	def saveResponse
#		if File.exist?(@settings['freedbCache'])
#			@metadataFile = YAML.load(File.open(@settings['freedbCache']))
#		else
#			@metadataFile = Hash.new
#		end
#
#		@metadataFile[@disc.freedbString] = @rawResponse
#
#		file = File.new(@settings['freedbCache'], 'w')
#		file.write(@metadataFile.to_yaml)
#		file.close()
#	end
#end

#	def undoVarArtist TODO
#		# first backup in case we want to revert back
#		@varArtistsBackup = @varArtists.dup()
#		@varTracklistBackup = @tracklist.dup()
#
#		# reset original values
#		@varArtists = Array.new
#
#		# restore the tracklist
#		@tracklist = @backupTracklist.dup
#	end

#reset to various artists when originally detected as such and made undone
#	def redoVarArtist TODO
#		if !@backupTracklist.empty? && !@varArtistsBackup.empty?
#			@tracklist = @varTracklistBackup
#			@varArtists = @varArtistsBackup
#		end
#	end
#end
