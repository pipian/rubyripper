#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/metadata/freedb/getFreedbRecord'
require 'cgi'

describe GetFreedbRecord do

  # helper function to return the query message in the stub
  def setQueryReply(query=nil)
    query ||= '200 blues 7F087C0A Some random artist / Some random album'
    network.should_receive(:setupConnection).once.with('cgi')
    network.should_receive(:encode).at_least(:once).with(anything()).and_return {|a| CGI.escape(a)}
    network.should_receive(:get).with(@query_disc).and_return query
  end

  # helper function to return the read message in the stub
  def setReadReply(category="blues", discid="7F087C0A", response=nil)
    request = "/~cddb/cddb.cgi?cmd=cddb+read+#{category}+#{discid}&hello=\
Joe+fakestation+rubyripper+test&proto=6"
    response ||= "210 metal 7F087C01\n" + @file + "\n."

    network.should_receive(:get).with(request).and_return response
  end

  before(:all) do
    @disc = "7F087C0A 10 150 13359 36689 53647 68322 81247 87332 \
106882 122368 124230 2174"
    @query_disc = "/~cddb/cddb.cgi?cmd=cddb+query+7F087C0A+10+150+13359+\
36689+53647+68322+81247+87332+106882+122368+124230+2174&hello=Joe+\
fakestation+rubyripper+test&proto=6"
    @file = 'A fake freedb record file'
  end

  let(:prefs) {double('Preferences').as_null_object}
  let(:network) {double('Network').as_null_object}
  let(:getFreedb) {GetFreedbRecord.new(network, prefs)}

  context "Given there is only an empty instance" do
    it "should not crash if there are no choices but the caller still chooses" do
      getFreedb.choose(0)
      getFreedb.status.should == 'noChoices'
      getFreedb.freedbRecord.should == nil
      getFreedb.category.should == nil
      getFreedb.finalDiscId == nil
    end
  end

  context "After firing a query for a disc to the freedb server" do

    before(:each) do
      prefs.should_receive(:hostname).at_least(:once).and_return 'fakestation'
      prefs.should_receive(:username).at_least(:once).and_return 'Joe'
      network.should_receive(:path).at_least(:once).and_return "/~cddb/cddb.cgi"
    end

    it "should handle the response in case no disc is reported" do
      setQueryReply('202 No match found')
      getFreedb.queryDisc(@disc)

      getFreedb.status.should == 'noMatches'
      getFreedb.freedbRecord.should == nil
      getFreedb.choices.should == nil
      getFreedb.category.should == nil
      getFreedb.finalDiscId == nil
    end

    it "should handle the error message when the database is corrupt" do
      setQueryReply('403 Database entry is corrupt')
      getFreedb.queryDisc(@disc)

      getFreedb.status.should == 'databaseCorrupt'
      getFreedb.freedbRecord.should == nil
      getFreedb.choices.should == nil
      getFreedb.category.should == nil
      getFreedb.finalDiscId == nil
    end

    it "should handle an unknown reply message" do
      setQueryReply('666 The number of the beast')
      getFreedb.queryDisc(@disc)

      getFreedb.status.should == 'unknownReturnCode: 666'
      getFreedb.freedbRecord.should == nil
      getFreedb.choices.should == nil
      getFreedb.category.should == nil
      getFreedb.finalDiscId == nil
    end

    it "should handle the response in case 1 record is reported" do
      setQueryReply()
      setReadReply()
      getFreedb.queryDisc(@disc)

      getFreedb.status.should == 'ok'
      getFreedb.freedbRecord.should == @file
      getFreedb.choices.should == nil
      getFreedb.category.should == 'metal'
      getFreedb.finalDiscId == '7F087C01'
    end

    it "should get the first response if multiple are reported when firstHit preference is true" do
      prefs.stub(:firstHit).and_return true
      choices = "blues 7F087C0A Artist A / Album A\nrock 7F087C0B Artist B / Album \
B\n\jazz 7F087C0C Artist C / Album C\n\country 7F087C0D Artist D / Album D\n."

      setQueryReply("211 code close matches found\n#{choices}")
      setReadReply()
      getFreedb.queryDisc(@disc)

      getFreedb.status.should == 'ok'
      getFreedb.freedbRecord.should == @file
      getFreedb.choices.should == choices[0..-3].split("\n")
      getFreedb.choices.length.should == 4
      getFreedb.category.should == 'metal'
      getFreedb.finalDiscId == '7F087C01'
    end

    context "when multiple records are reported and the user wishes to choose" do
      before(:each){prefs.stub(:firstHit).and_return false}

      it "should allow choosing the first disc" do
        choices = "blues 7F087C0A Artist A / Album A\nrock 7F087C0B Artist B / Album \
B\n\jazz 7F087C0C Artist C / Album C\n\country 7F087C0D Artist D / Album D\n."

        setQueryReply("211 code close matches found\n#{choices}")
        setReadReply()
        getFreedb.queryDisc(@disc)

        getFreedb.status.should == 'multipleRecords'
        getFreedb.freedbRecord.should == nil
        getFreedb.choices.should == choices[0..-3].split("\n")
        getFreedb.choices.length.should == 4

        # choose the first disc
        getFreedb.choose(0)
        getFreedb.status.should == 'ok'
        getFreedb.freedbRecord.should == @file
        getFreedb.category.should == 'metal'
        getFreedb.finalDiscId == '7F087C01'
      end

      it "should allow choosing the second disc" do
        choices = "blues 7F087C0A Artist A / Album A\nrock 7F087C0B Artist B / Album \
B\n\jazz 7F087C0C Artist C / Album C\n\country 7F087C0D Artist D / Album D\n."

        setQueryReply("211 code close matches found\n#{choices}")
        setReadReply('rock', '7F087C0B')
        getFreedb.queryDisc(@disc)

        # choose the second disc
        getFreedb.choose(1)
        getFreedb.status.should == 'ok'
        getFreedb.freedbRecord.should == @file
        getFreedb.category.should == 'metal'
        getFreedb.finalDiscId == '7F087C01'
      end

      it "should allow choosing an invalid choice without crashing" do
        choices = "blues 7F087C0A Artist A / Album A\nrock 7F087C0B Artist B / Album \
B\n\jazz 7F087C0C Artist C / Album C\n\country 7F087C0D Artist D / Album D\n."

        setQueryReply("211 code close matches found\n#{choices}")
        getFreedb.queryDisc(@disc)

        # choose an unknown
        getFreedb.status.should == 'multipleRecords'
        getFreedb.choose(4)
        getFreedb.status.should == 'choiceNotValid: 4'
        getFreedb.freedbRecord.should == nil
        getFreedb.category.should == nil
        getFreedb.finalDiscId == nil
      end
    end

    context "When requesting a specific disc and an error is returned" do
      it "should handle the response when the disc is not found" do
        setQueryReply()
        setReadReply('blues', '7F087C0A', '401 Cddb entry not found')
        getFreedb.queryDisc(@disc)

        getFreedb.status.should == 'cddbEntryNotFound'
        getFreedb.freedbRecord.should == nil
      end

      it "should handle an unknown response code" do
        setQueryReply()
        setReadReply('blues', '7F087C0A', '666 The number of the beast')
        getFreedb.queryDisc(@disc)

        getFreedb.status.should == 'unknownReturnCode: 666'
        getFreedb.freedbRecord.should == nil
      end

      it "should handle a server (402) error response on the server" do
        setQueryReply()
        setReadReply('blues', '7F087C0A', '402 There is a temporary server error')
        getFreedb.queryDisc(@disc)

        getFreedb.status.should == 'serverError'
        getFreedb.freedbRecord.should == nil
      end

      it "should handle a database (403) error response on the server" do
        setQueryReply()
        setReadReply('blues', '7F087C0A', '403 Database inconsistency error')
        getFreedb.queryDisc(@disc)

        getFreedb.status.should == 'databaseCorrupt'
        getFreedb.freedbRecord.should == nil
      end
    end
  end
end
