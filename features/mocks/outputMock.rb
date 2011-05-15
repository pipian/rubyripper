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

# a class to fake output
class OutputMock
  # maken an array to store all info
  def initialize
    @output = Array.new
  end

  # is the text printed to the screen?
  def visible?(text, matchCompleteLine=true)
    @visible = false
    matchCompleteLine ? matchCompleteLine(text) : matchInLine(text)
    logOutput() if @visible == false
    return @visible
  end

  def matchCompleteLine(text)
    @output.each{|line| (@visible=true ; break) if line == text}
  end

  def matchInLine(text)
    @output.each{|line| (@visible=true ; break) if line.include?(text)}
  end

  def logOutput
    `echo #{@output} > /tmp/rspec.txt`
  end

  def puts(string)
    @output << string
  end

  def print(string)
    @output << string.chomp()
  end
end
