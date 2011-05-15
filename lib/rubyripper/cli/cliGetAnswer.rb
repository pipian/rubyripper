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

# return an answer from the user, typed into the screen
class CliGetAnswer
  @@in = $stdin
  def initialize(out=nil)
    @out = out ? out : $stdout
  end

  # to easily override the input
  def setInput(input)
    @@in = input
  end

  # get the input from the user
  def get(question, default)
    @out.print(question + " [#{default}] : ")
    input = @@in.gets.strip
    return input.empty? ? default : input
  end
end

# return a boolean value from the user, subclasses from GetAnswer
class CliGetBool < CliGetAnswer

  # get a boolean value from the user
  def initialize(out)
    super(out)
    @valid = {_("yes") => true, _('y') => true, _("no") => false, _("n") =>false}
  end

  # get the input from the user
  def get(question, default)
    input = super

    if !@valid.key?(input)
      @out.print("Please answer #{_('yes')} or #{_('no')}. Try again.\n")
      get(question, default)
    else
      return @valid[input]
    end
  end
end

# return an integer value from the user, subclasses from GetAnswer
class CliGetInt < CliGetAnswer

  def initialize(out)
    super(out)
  end

  # get the input from the user
  def get(question, default)
    input = super
    if input == default
      return default
    # 0 may be a valid response, but any string.to_i == 0
    elsif input.to_i > 0 || input == "0"
      return input.to_i
    else
      @out.print("Please enter an integer value. Try again.\n")
      get(question, default)
    end
  end
end

# return an answer from the user, typed into the screen
class CliGetString < CliGetAnswer

  # get the input from the user
  #def get(question, default)
  #super
  #end
end
