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
  require 'rubyripper/cli/cliGetAnswer'
  require 'rubyripper/cli/cliPreferences'
  require 'rubyripper/cli/cliDisc'
rescue LoadError
  puts 'The rubyripper lib files can\'t be found!'
  puts 'Perhaps you need to add the directory to the RUBYLIB variable?'
  exit()
end

# The class that initiates the commandline interface
class CommandLineInterface

  # start up the interface
  def initialize(prefs=nil, deps=nil, disc=nil, int=nil)
    @deps = deps ? deps : Dependency.new
    @int = int ? int : CliGetInt.new
    @cliPrefs = prefs ? prefs : CliPreferences.new(@int)
    @cliDisc = disc ? disc : CliDisc.new(@cliPrefs.prefs, @int)
  end

  def start
    @rippingLog = ""
    @rippingProgress = 0.0
    @encodingProgress = 0.0
    prepare()
    loopMainMenu()
  end

  # Name of the frontend, used in InstanceHelper class
  def name ; return 'cli' ; end

  # The only function where the lib files are reporting to
  def update(modus, value=false)
    if modus == "ripping_progress"
      progress = "%.3g" % (value * 100)
      puts "Ripping progress (#{progress} %)"
    elsif modus == "encoding_progress"
      progress = "%.3g" % (value * 100)
      puts "Encoding progress (#{progress} %)"
    elsif modus == "log_change"
      print value
    elsif modus == "error"
      print value
      print "\n"
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
    puts "Rubyripper version #{$rr_version}"
    @deps.verify()
    @cliPrefs.read()
    @cliDisc.show()
  end

  # Display the different options
  def showMainMenu
    puts ""
    puts _("*** RUBYRIPPER MAIN MENU ***")
    puts ""
    puts ' 1) ' + _('Change preferences')
    puts ' 2) ' + _('Change metadata')
    puts ' 3) ' + _('Change tracks to rip (default = all)')
    puts ' 4) ' + _('Rip the disc!')
    puts '99) ' + _("Exit rubyripper...")
    puts ""
    @int.get("Please type the number of your choice", 4)
  end

  #  Loop through the main menu
  def loopMainMenu
    choice = showMainMenu()
    if choice == 99
      puts _("Thanks for using rubyripper.")
      puts _("Have a nice day!")
      exit()
    else
      if choice == 1 ; @cliPrefs.show()
      elsif choice == 2 ; @cliDisc.show()
      elsif choice == 3
        puts 'TODO: implement the track selection menu'
        # TODO @inst.get('cliTracklist').chooseTracks()
      elsif choice == 4
        puts 'TODO: implement the rip action'
        # TODO
      else
        puts _("Number #{choice} is not a valid choice, try again")
      end
      loopMainMenu()
    end
  end

  # Show the disc info and include error handling
  def getDiscInfo()
    if @discCli.getError
      puts @discCli.getError
      if getAnswer(_("Do you want to change your settings? "), "yes", _('y'))
        @settingsCli.editSettings()
        getDiscInfo()
      end
      exit()
    end
  end

  # cancel the rip
  def cancelRip()
    puts _("Rip is canceled, exiting...")
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
    puts _("The output directory already exists. What would you like to do?")
    puts ""
    puts _("1) Auto rename the output directory")
    puts _("2) Overwrite the existing directory")
    puts _("3) Cancel the rip and eject the disc")
    puts ""

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

