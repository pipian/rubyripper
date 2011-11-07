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

require 'rubyripper/system/dependency'
require 'rubyripper/preferences/main'
require 'net/http' #automatically loads the 'uri' library
require 'cgi'#for translating characters to HTTP codes, space = %20 for instance

# This class handles all connectivity with a http server
class Network
  attr_reader :path
  attr_writer :type

  def initialize(prefs=nil, deps=nil, uri=nil, http=nil, cgi=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @deps = deps ? deps : Dependency.instance()
    @uri = uri ? uri : URI
    @http = http ? http : Net::HTTP
    @cgi = cgi ? cgi : CGI
  end
  
  # make a connection of a certain type
  def setupConnection(type='cgi')
    if type == 'cgi'
      @type = 'cgi'
      setupCgiConnection()
    end
  end

  # fire up a CGI command to the server
  def get(query)
    if @type == 'cgi'
      responsCode, answer = @connection.get(query)
    end
    return answer
  end
  
  # encode for a specific protocol in order to escape certain characters
  def encode(string)
    if @type == 'cgi'
      @cgi.escape(string)
    end
  end

private
  # first configure the connection (with proxy if needed)
  def setupCgiConnection
    url = @uri.parse(@prefs.site)

    if @deps.env('http_proxy')
      proxy = @uri.parse(@deps.env('http_proxy'))
      @connection = @http.new(url.host, url.port, proxy.host,
      proxy.port, proxy.user, proxy.password ? @cgi.unescape(proxy.password) : '')
    else
      @connection = @http.new(url.host, url.port)
    end
    @path = url.path
  end
end
