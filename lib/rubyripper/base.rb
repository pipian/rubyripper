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

# The current version of Rubyripper
$rr_version = '0.7.0a1'

# Crash on errors, because bugs are otherwise hard to find
Thread.abort_on_exception = true

# Make sure the locale files work before installing
ENV['GETTEXT_PATH'] = File.expand_path('../../../data/locale',__FILE__)

major_version = RUBY_VERSION.delete('.')[0..1].to_i
if major_version < 19
  puts "Ruby versions older than the 1.9 release are not supported anymore"
  puts "Please upgrade ruby to a recent version."
  exit()
end


begin
  raise() if ENV.key?('cucumber')
  require 'gettext'

  class TestIfGetTextDoesNotCrash
    include GetText
    bindtextdomain("rubyripper")
    _("test")
  end
rescue Exception => error
  unless ENV.key?('cucumber')
    if error.class == LoadError
      puts "ruby-gettext is not found. Translations are disabled!" 
    elsif error.class == NoMethodError
      puts error.exception()
      puts error.backtrace()
      puts "ruby-gettext is crashing. Translations are disabled!"
    end
  end

  module GetText
    def _(txt) ; txt ; end
    def GetText._(txt) ; txt ; end
    def GetText.bindtextdomain(domain) ; end
  end
end

