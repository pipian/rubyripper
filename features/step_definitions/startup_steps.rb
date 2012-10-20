#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011  Bouke Woudstra (boukewoudstra@gmail.com)
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

Given /^rubyripper will find "([^"]*)" is inserted$/ do |disc|
  @testdisc = File.expand_path("#{File.dirname(__FILE__)}/../testdata/disc")
  if disc == 'no audio disc'
    @testdisc = File.join(@testdisc, 'noAudioDisc')
  elsif disc == 'Motorhead/Inferno'
    @testdisc = File.join(@testdisc, 'normalAudioDisc')
  elsif disc == 'aLatinEncodedDisc'
    @testdisc = File.join(@testdisc, 'latinEncodedDisc')
  else
    raise "Unknown disc from cucumber!"
  end
end

When /I run rubyripper in cli mode\s*/ do
  @file = File.expand_path("#{File.dirname(__FILE__)}/../testdata/settings")
  run_interactive "rubyripper_cli --testdisc #{@testdisc} --file #{@file}"
end

When /^I choose "([^"]*)"\s*/ do |menuOption|
  type menuOption
end

When /^I press ENTER "([^"]*)" times to close the application$/ do |amount|
  amount.to_i.times{type('')}
end

When /^I change each preferences item in the menu$/ do |table|
  table.raw.each do |preference, input|
    type preference
    type input unless input.empty?
  end
end
