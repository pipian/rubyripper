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

# helper for interpreting commandline options
require 'optparse'

# Interpretes the parameters when loaded
class CliArguments
  include GetText
  GetText.bindtextdomain("rubyripper")
  
  attr_reader :options

  def initialize(out=nil)
    @out = out ? out : $stdout
  end

  # Make sure the commandline options are interpreted
  def parse
    @options = {'file' => false, 'version' => false, 'verbose' => false,
'configure' => false, 'defaults' => false, 'help' => false, 'testdisc' => false, 'batch' => false}
    setParseOptions()
    getParseOptions()
  end

private

  # First define the different options
  def setParseOptions
    @opts = OptionParser.new(banner = nil, width = 20, indent = ' ' * 2) do |opts|
      opts.on("-V", "--version", _("Show current version of rubyripper.")) do
        @options['version'] = true
        @out.puts _("Rubyripper version %s") % [$rr_version]
      end

      opts.on("-f", "--file <FILE>", _("Load configuration settings from file <FILE>.")) do |f|
        @options['file'] = f
      end

      opts.on("-v", "--verbose", _("Display verbose output.")) do |v|
        @options['verbose'] = v
      end

      opts.on("-c", "--configure", _("Change configuration settings.")) do |c|
        @options['configure'] = c
      end

      opts.on("-d", "--defaults", _("Skip questions and rip the disc.")) do |d|
        @options['defaults'] = true
      end

      opts.on("--testdisc <CD>", _("Provide a directory to stub disc queries.")) do |t|
        @options['testdisc'] = t
      end

      opts.on("-B", "--batch", _("Exit after the disc is done ripping.")) do |t|
        @options['batch'] = t
      end

      opts.on_tail("-h", "--help", _("Show this usage statement.")) do |h|
        @out.puts opts
        @options['help'] = h
      end
    end
  end

  # Then read the different options
  def getParseOptions
    begin
      @opts.parse!(ARGV)
    rescue Exception => e
      @out.puts "The loading of the input switches crashed.", e, @opts
      exit()
    end

    if @options['help'] || @options['version']; exit end

    @out.puts _("Verbose output specified.") if @options['verbose']
    @out.puts _("Configure option specified.") if @options['configure']
    @out.puts _("Skip questions and rip the disc.") if @options['defaults']
    @out.puts _("Use config file ") + @options['file'] if @options['file']
  end
end
