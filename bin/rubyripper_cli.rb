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

# set the directory of the local installation
$localdir = File.expand_path(File.dirname(File.dirname(__FILE__)))

# Put the local lib directory on top of the ruby default lib search path
$:.insert(0, File.expand_path('../../lib', __FILE__))

# Try to find the rubyripper lib files
begin
  require 'rubyripper/base'
  require 'rubyripper/dependency'
  require 'rubyripper/errors'
  require 'rubyripper/cli/cliGetAnswer'
  require 'rubyripper/cli/cliPreferences'
  require 'rubyripper/cli/cliDisc'
  require 'rubyripper/cli/cliTracklist'
rescue LoadError
  puts 'The rubyripper lib files can\'t be found!'
  puts 'Perhaps you need to add the directory to the RUBYLIB variable?'
  exit()
end

# The class that initiates the commandline interface
class CommandLineInterface

  # start up the interface
  def initialize(out=nil, prefs=nil, deps=nil, disc=nil, int=nil, tracks=nil)
    @out = out ? out : $stdout
    @deps = deps ? deps : Dependency.new
    @int = int ? int : CliGetInt.new(@out)
    @cliPrefs = prefs ? prefs : CliPreferences.new(@out, @int)
    @cliDisc = disc ? disc : CliDisc.new(@out, @cliPrefs.prefs, @int)
    @cliTracklist = tracks ? tracks : CliTracklist.new(@out, @int, @cliPrefs.prefs, @cliDisc)
  end

  def start
    @rippingLog = ""
    @rippingProgress = 0.0
    @encodingProgress = 0.0
    prepare()
    loopMainMenu()
  end

  # The only function where the lib files are reporting to
  def update(modus, value=false)
    if modus == "ripping_progress"
      progress = "%.3g" % (value * 100)
      @out.puts "Ripping progress (#{progress} %)"
    elsif modus == "encoding_progress"
      progress = "%.3g" % (value * 100)
      @out.puts "Encoding progress (#{progress} %)"
    elsif modus == "log_change"
      @out.print value
    elsif modus == "error"
      @out.print value
      @out.print "\n"
      if get_answer(_("Do you want to change your settings? (y/n) : "), "yes",_("y"))
        @settingsInfo.editSettings()
      end
    elsif modus == "dir_exists"
      dirExists()
    end
  end

private

  # check dependencies, read the preferences and show the disc
  def prepare
    @out.puts _("Rubyripper version %s") % [$rr_version]
    @out.puts ""
    @deps.verify()
    @cliPrefs.read()
    @cliDisc.show()
  end

  # Display the different options
  def showMainMenu
    @out.puts _("* RUBYRIPPER MAIN MENU *")
    @out.puts ""
    @out.puts ' 1) ' + _('Change preferences')
    @out.puts ' 2) ' + _('Scan drive for audio disc')
    @out.puts ' 3) ' + _('Change metadata')
    @out.puts ' 4) ' + _('Select the tracks to rip (default = all)')
    @out.puts ' 5) ' + _('Rip the disc!')
    @out.puts '99) ' + _("Exit rubyripper...")
    @out.puts ""
    @int.get("Please type the number of your choice", 99)
  end

  #  Loop through the main menu
  def loopMainMenu
    case choice = showMainMenu()
      when 99
        @out.puts _("Thanks for using rubyripper.")
        @out.puts _("Have a nice day!")
      when 1 then @cliPrefs.show()
      when 2 then @cliDisc.show()
      when 3 then @cliDisc.changeMetadata()
      when 4 then @cliTracklist.show()
      when 5 then startRip()
    else @out.puts _("Number #{choice} is not a valid choice, try again")
    end

    loopMainMenu() unless choice == 99
  end

  # launch the ripping process
  def startRip()
    require 'rubyripper/rubyripper'
    @out.puts 'TODO: finish implementation of the rip action'

    @rubyripper = Rubyripper.new(@cliPrefs.prefs, self, @cliDisc.cd,
    @cliTracklist.selection)

    errors = @rubyripper.checkConfiguration()
    errors.empty? ? @rubyripper.startRip() : showErrors(errors)
  end

  # show the messages and return to main menu
  def showErrors(errors)
    @out.puts ''
    @out.puts _("Please solve the following configuration errors first:")
    errors.each{|error| @out.puts '  > ' + Errors.send(error[0], error[1])}
    @out.puts ""
  end

  # cancel the rip
  def cancelRip()
    @out.puts _("Rip is canceled, exiting...")
    eject(@settings['cd'].cdrom)
    exit()
  end

  # get the tracks, verify the settings
  def prepareRip()
    @settings['tracksToRip'] = CliTracklist.new(@settings, @discInfo.getStatus)

    # starts some check if the settings are sane
    @rubyripper = Rubyripper.new(@settings, self)
    status = @rubyripper.settingsOk
    if status == true
      @rubyripper.startRip()
    else
      update(status[0], status[1])
    end
  end

  # A dialog in case the output directory exists
  def dirExists
    @out.puts _("The output directory already exists. What would you like to do?")
    @out.puts ""
    @out.puts _("1) Auto rename the output directory")
    @out.puts _("2) Overwrite the existing directory")
    @out.puts _("3) Cancel the rip and eject the disc")
    @out.puts ""

    answer = get_answer(_("Please enter the number of your choice: "), "number", 1)
    if answer == 1; @rubyripper.postfixDir() ; @rubyripper.startRip()
    elsif answer == 2; @rubyripper.overwriteDir() ; @rubyripper.startRip()
    else cancelRip()
    end
  end
end

if __FILE__ == $0
  app = CommandLineInterface.new()
  app.start()
end

