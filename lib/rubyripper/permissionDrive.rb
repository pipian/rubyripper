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

# check the permissions of the drive
class PermissionDisc

	# * cdrom = location of cdrom drive
	# * query = cdparanoia query
	# * deps = instance of Dependency class
	def initialize(cdrom='/dev/cdrom', query, deps)
		@cdrom = cdrom		
		@query = query
		@deps = deps

		@status = _('ok')
		
		checkDevice()
		if @query.include?('generic device: ')
			checkGenericDevice()
		end
	end

	# if succesfull, return _('ok')
	def status ; return @status end

private

	# first lookup the real drive, then check permissions
	def checkDevice
		while File.symlink?(@cdrom)
			link = File.readlink(@cdrom)
			if (link.include?('..') || !link.include?('/'))
				@cdrom = File.expand_path(File.join(File.dirname(@cdrom), link))
			else
				@cdrom = link
			end
		end
		
		unless File.blockdev?(@cdrom) #is it a real device?
			@status = _("ERROR: Cdrom drive %s does not exist on your system!\n\
Please configure your cdrom drive first.") % [@cdrom]
			return false
		end
			
		unless (File.readable?(@cdrom) && File.writable?(@cdrom))
			@status = _("You don't have read and write permission for device\n
%s on your system! These permissions are necessary for\n
cdparanoiato scan your drive. You might want to add yourself\n
to the necessary group with gpasswd.") % [@cdrom]
			if @deps.getDeps('ls')
				permission = `ls -l #{@cdrom}`
				@status +=	_("\n\nls -l shows %s") % [permission]
			end
		end
	end

	# lookup the scsi device and it's permissions
	def checkGenericDevice
		@query.each do |line|
			if line =~ /generic device: /
				device = $'.strip() #the part after the match
				break #end the loop
			end
		end
		
		unless ((File.chardev?(device) || File.blockdev?(device)) && File.readable?(device) && File.writable?(device))
			permission = nil
			if File.chardev?(device) && @deps.getDeps['ls']
				permission = `ls -l #{device}`
			end
			
			@status = _("You don't have read and write permission\n"\
			"for device %s on your system! These permissions are\n"\
			"necessary for cdparanoia to scan your drive.\n\n%s\n"\
			"You might want to add yourself to the necessary group with gpasswd")\
			%[device, "#{if permission ; "ls -l shows #{permission}" end}"]
			
			return false
		end
		
		return true
	end
end
