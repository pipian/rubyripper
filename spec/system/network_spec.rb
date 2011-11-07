#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/system/network'

describe Network do

  let(:prefs) {double('Preferences').as_null_object}
  let(:deps) {double('Dependency').as_null_object}
  let(:uri) {double('URI').as_null_object}
  let(:url) {double('URL').as_null_object}
  let(:proxy) {double('Proxy').as_null_object}
  let(:http) {double('NetHttp').as_null_object}
  let(:cgi) {double('CGI').as_null_object}
  let(:network) {Network.new(prefs, deps, uri, http, cgi)}

  context "When setting up a CGI connection" do
    before(:each) do
      prefs.should_receive(:site).once
      url.should_receive(:host).once.and_return 1
      url.should_receive(:port).once.and_return 2
      url.should_receive(:path).once.and_return 3
    end
    
    it "should be able to do so without a proxy" do
      deps.should_receive(:env).with('http_proxy').once().and_return nil
      uri.should_receive(:parse).once.and_return(url)
      http.should_receive(:new).with(1, 2)
      
      network.setupConnection('cgi')
      network.path.should == 3
    end
    
    it "should be able to do so with a proxy with no password" do
      deps.should_receive(:env).with('http_proxy').twice().and_return 4
      uri.should_receive(:parse).once.and_return(url)
      proxy.should_receive(:host).and_return 5
      proxy.should_receive(:port).and_return 6
      proxy.should_receive(:user).and_return 7
      proxy.should_receive(:password).and_return false
      uri.should_receive(:parse).with(4).and_return proxy
      http.should_receive(:new).with(1, 2, 5, 6, 7, '')
      
      network.setupConnection('cgi')
      network.path.should == 3
    end
  end
end
