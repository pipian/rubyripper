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

require 'rubyripper/musicbrainz/musicbrainzWebService'

# needed to test query
$rr_version = 'test'

describe MusicBrainzWebService do

  it "should return the path correctly and configure only once" do
    mock_connection = mock('@connection')
    Net::HTTP.should_receive(:new).and_return(mock_connection)
    @mbws = MusicBrainzWebService.new
    @mbws.path.should == "/ws/2/"
    @mbws.path.should == "/ws/2/"
  end

  it "should set the User-Agent header on all calls to get" do
    mock_connection = mock('@connection')
    Net::HTTP.should_receive(:new).and_return(mock_connection)
    query = 'query'
    mock_connection.should_receive(:get).with(query, {'User-Agent'=>"rubyripper/test"}).and_return([200, 'response'])
    @mbws = MusicBrainzWebService.new
    @mbws.get(query).should == 'response'
  end

end
