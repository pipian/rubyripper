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

# A class to fake http traffic with freedb server
class FakeHttpConnection
	
	# query = first response, read = freedbRecord, category = genre, discid = discid
	def initialize(query, read)
		update(query, read)
		@config = false
		@inputQuery = Array.new
	end

	# allow the config to be checked
	def config ; return @config ; end

	# allow the input queries to be checked
	def inputQuery ; return @inputQuery ; end

	# skip http configuration, faking the connection
	def configConnection(url) ; @config = true ; end

	# refresh the variables
	def update (query, read)
		@query = query
		@read = read
	end

	# simulate server response and validate query
	def get(query)
		@inputQuery << query
		if query.include?('query')
			return @query
		elsif query.include?('read')
			return @read
		else
			raise "query #{query} not recognized"
		end
	end
end
