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

# a class to fake input
# All user input is channeled through the GetAnswer class and childs.
# The input object is an instance variable, so override it with ourself.
class InputMock

  def initialize
    @input = Array.new
    a = CliGetAnswer.new
    a.setInput(self)
  end

  # Add another input (without the ENTER)
  def add(text)
    @input << (text.to_s + "\n")
  end

  def pressEnter(amount)
    amount.times{@input << "\n"}
  end

  # fake function to simulate input, return first line
  def gets
    @input.empty? ? '' : @input.shift()
  end
end

