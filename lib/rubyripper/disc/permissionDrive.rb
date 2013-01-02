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

require 'rubyripper/system/dependency'

# This class checks the permissions of the drive
# Used by ScanDiscCdparanoia to check potential problems later on
class PermissionDrive
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :error

  # * dependency = instance of Dependency class
  def initialize(prefs=nil, deps=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @deps = deps ? deps : Dependency.instance()
    @error = nil
  end
  
  # before trying to query cdparanoia check if permissions of the drive are ok
  def problems?(cdrom)
    @cdrom = cdrom
    checkDevice()
    return !(@error.nil? || @prefs.testdisc)
  end
  
  # before ripping make sure scsi drive permission are ok as well
  # * query = cdparanoia query
  def problemsSCSI?(query)
    @query = query
    checkGenericDevice()
    return !(@error.nil? || @prefs.testdisc)
  end

private

  # first lookup the real drive, then check permissions
  # a block device is required on linux, not on other platforms (issue 480)
  # writable access is required on linux, not on other platforms (issue 488)
  def checkDevice
    getRealDevice()
    isBlockDevice? if @deps.platform =~ /linux/
    isDriveReadable?
    isDriveWritable? if @deps.platform =~ /linux/
  end
  
  # a generic drive means a scsi drive
  def checkGenericDevice
     if @query.include?('generic device: ')
       drive = getGenericDrive()
       genericDeviceChecks(drive)
     end
  end

  # return the drive behind the symlink
  def getRealDevice
    while File.symlink?(@cdrom)
      link = File.readlink(@cdrom)
      if (link.include?('..') || !link.include?('/'))
        @cdrom = File.expand_path(File.join(File.dirname(@cdrom), link))
      else
        @cdrom = link
      end
    end
  end
  
  # check if it is not a fake device
  def isBlockDevice?
    if not File.blockdev?(@cdrom)
      @error = _("ERROR: Cdrom drive %s does not exist on your system!\n\
Please configure your cdrom drive first.") % [@cdrom]
    end
  end
  
  # check is the user has read permissions for the drive
  def isDriveReadable?
    unless File.readable?(@cdrom)
      @error = _("You don't have read permissions for device\n
%s on your system! These permissions are necessary for\n
cdparanoia to scan your drive. You might want to add yourself\n
to the necessary group with gpasswd.") % [@cdrom]
      if @deps.installed?('ls')
        permission = `ls -l #{@cdrom}`
        @error +=  _("\n\nls -l shows %s") % [permission]
      end
    end
  end
  
  # check if the user has write permissions for the drive
  def isDriveWritable?
    unless File.writable?(@cdrom)
      @error = _("You don't have write permissions for device\n
%s on your system! These permissions are necessary for\n
cdparanoia to scan your drive. You might want to add yourself\n
to the necessary group with gpasswd.") % [@cdrom]
      if @deps.installed?('ls')
        permission = `ls -l #{@cdrom}`
        @error +=  _("\n\nls -l shows %s") % [permission]
      end
    end
  end
  
  # detect the generic drive (if it exists) with the cdparanoia query
  def getGenericDrive
    @query.each do |line|
      if line =~ /generic device: /
        drive = $'.strip() #the part after the match
        break #end the loop
      end
    end
    return drive
  end

  # lookup the scsi device and it's permissions
  def genericDeviceChecks(drive)
    unless ((File.chardev?(drive) || File.blockdev?(drive)) && File.readable?(drive) && File.writable?(drive))
      permission = nil
      if File.chardev?(drive) && @deps.installed?('ls')
        permission = `ls -l #{drive}`
      end

      @error = _("You don't have read and write permission\n"\
      "for device %s on your system! These permissions are\n"\
      "necessary for cdparanoia to scan your drive.\n\n%s\n"\
      "You might want to add yourself to the necessary group with gpasswd")\
      %[device, "#{if permission ; "ls -l shows #{permission}" end}"]
    end
  end
end
