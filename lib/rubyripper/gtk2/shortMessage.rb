#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

# ShortMessage handles the rubyripper window while displaying a message.
# Notice that the left part of the gui with the icons is not in this class

class ShortMessage
attr_reader :display

	def initialize(cdrom)
		@display = Gtk::Label.new(_("Welcome to rubyripper %s.\nScanning drive %s for an audio disc...") % [$rr_version, cdrom])
	end
	
	def no_disc_found(cdrom)
		@display.text = _("No disc found in %s!\nPlease insert a disc and push 'Scan drive'.\n\nThe cdrom drive can be set in 'Preferences'.") % [cdrom]
	end
	
	def open_tray(cdrom)
		@display.text = _("Opening tray of drive %s") % [cdrom]
	end
	
	def close_tray(cdrom)
		@display.text = _("Closing tray of drive %s. \n\nThe drive will be scanned for an audio disc...") % [cdrom]
	end
	
	def ask_for_disc
		@display.text = _("Insert an audio-disc and press 'Close tray'.\nThe drive will automatically be scanned for a disc.\n\nIf the tray is already closed, press 'Scan drive'")
	end
	
	def no_eject_found
		@display.text = _("The eject utility is not found on your system!")
	end
	
	def show_message(message)
		@display.text = message
	end
end
