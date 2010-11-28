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

# MultipleFreedbHitse handles the rubyripper window while displaying the dialog
# when multiple freedb hits are offered to the user.
# Notice that the left part of the gui with the icons is not in this class

class MultipleFreedbHits
attr_reader :display

	def initialize(value, main_instance)
		@label1 = Gtk::Label.new(_("The freedb server reports multiple hits.\nWhich one would you prefer?"))
		@image1 = Gtk::Image.new(Gtk::Stock::DIALOG_QUESTION, Gtk::IconSize::DIALOG)
		@hbox1 = Gtk::HBox.new
		[@image1, @label1].each{|object| @hbox1.pack_start(object)}
		
		@combobox = Gtk::ComboBox.new(true) # text only		
		value.each{|freedb_hit| @combobox.append_text(freedb_hit)}
		@separator1 = Gtk::HSeparator.new
		@hbox2 = Gtk::HBox.new
		@hbox2.pack_start(@combobox, false,false,5)
		
		@button1 = Gtk::Button.new
		@label2 = Gtk::Label.new(_("Ok"))
		@image2 = Gtk::Image.new(Gtk::Stock::OK, Gtk::IconSize::LARGE_TOOLBAR)
		@hbox3 = Gtk::HBox.new
		[@image2, @label2].each{|object| @hbox3.pack_start(object,false,false,15)}
		@button1.add(@hbox3)
		@hbox4 = Gtk::HBox.new
		@hbox4.pack_start(@button1,true,false)
		
		@vbox1 = Gtk::VBox.new
		@vbox1.border_width = 10
		[@hbox1, @hbox2, @separator1, @hbox4].each{|object| @vbox1.pack_start(object,false,false,10)}
		
		@display = Gtk::Frame.new(_("Multiple hits found...")) # will contain the above
		@display.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@display.border_width = 5
		@display.add(@vbox1)
		@button1.signal_connect("released") do
			Thread.new do
				main_instance.change_display(main_instance.instances['GtkMetadata'])
				main_instance.handleFreedb(@combobox.active)
			end
		end
	end
end
