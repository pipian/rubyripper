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

# TODO require 'timeout' # in case of no connection

require 'net/http' #automatically loads the 'uri' library
#require 'cgi' #for translating characters to HTTP codes, space = %20 for instance

# This class handles all connectivity with a http server
class CgiHttpHandler
  attr_reader :path
  
  def initialize(preferences)
    @prefs = preferences
    @path = nil
  end

  # first configure the connection (with proxy if needed)
  def config
    url = URI.parse(@prefs.get('site'))
    @path = url.path
    
    if ENV['http_proxy']
      proxy = URI.parse(ENV['http_proxy'])
      @connection = Net::HTTP.new(url.host, url.port, proxy.host,
      proxy.port, proxy.user, proxy.password ? CGI.unescape(proxy.password) : '')
    else
      @connection = Net::HTTP.new(url.host, url.port)
    end
  end

  # ask for a single line from the server
  def get(query)
    responsCode, answer = @connection.get(query)
    return answer
  end
end
