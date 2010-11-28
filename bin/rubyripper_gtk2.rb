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

ICONDIR=[ENV['PWD'], "/usr/local/share/icons/hicolor/128x128/apps"]
RUBYDIR=[ENV['PWD'], File.dirname(__FILE__), "/usr/local/lib/ruby/site_ruby/1.8"]

found_rrlib = false
RUBYDIR.each do |dir|
  if File.exist?(file = File.join(dir, '/rr_lib.rb'))
	require file; found_rrlib = true ; break
  end
end
if found_rrlib == false
  puts "The main program logic file 'rr_lib.rb' can't be found!"
  exit()
end

begin
	require 'gtk2'
rescue LoadError
	puts "The ruby-gtk2 library could not be found. Is it installed?"; exit()
end

# The class defines the Rubyripper window.
# It has a variable frame in it, that can be
# replaced with other Gtk2 classes.

class GraphicalUserInterface
attr_reader :instances

	def initialize
		@instances = {'Preferences' => false, 'GtkMetadata' => false, 'ShortMessage' => false, 'RipStatus' => false, 'DirExists' => false, 'MultipleFreedbHits' => false, 'Summary' => false}
		@current_instance = false
		@gtk_window = Gtk::Window.new('Rubyripper')
		ICONDIR.each{|dir| if File.exist?(file = File.join(dir, 'rubyripper.png')) ; @gtk_window.icon = Gdk::Pixbuf.new(file) ; break end }
		@gtk_window.set_default_size(530, 440) #width, height
		
		@hbox1 = Gtk::HBox.new(false,5)

		create_buttonbox()
		create_signals()
		
		@settingsClass = Settings.new()
		@settings = @settingsClass.settings
		welcome_message()
		
		@lock = Monitor.new()
		@updateThread = nil
		@gtk_window.show_all() #The user interface is up, now load the library
		scan_drive()
	end
	
	def create_buttonbox #left side of the window, above the statusbar
		@vbuttonbox1 = Gtk::VButtonBox.new #child of @hbox1
		@buttons = [Gtk::Button.new, Gtk::Button.new, Gtk::Button.new, Gtk::Button.new, Gtk::Button.new]
		@buttons[3].sensitive = false #only activate the RipCdNow button when a disc is found
		@buttontext = [Gtk::Label.new('_'+_('Preferences'),true), Gtk::Label.new('_'+_("Scan drive"), true), Gtk::Label.new('_'+_("Open tray"),true), Gtk::Label.new('_'+_("Rip cd now!"),true), Gtk::Label.new('_'+_("Exit"),true)]
		@buttonicons = [Gtk::Image.new(Gtk::Stock::PREFERENCES, Gtk::IconSize::LARGE_TOOLBAR), Gtk::Image.new(Gtk::Stock::REFRESH, Gtk::IconSize::LARGE_TOOLBAR), Gtk::Image.new(Gtk::Stock::GOTO_BOTTOM, Gtk::IconSize::LARGE_TOOLBAR), Gtk::Image.new(Gtk::Stock::CDROM, Gtk::IconSize::LARGE_TOOLBAR), Gtk::Image.new(Gtk::Stock::QUIT, Gtk::IconSize::LARGE_TOOLBAR)]
		@vboxes = [Gtk::VBox.new, Gtk::VBox.new, Gtk::VBox.new,  Gtk::VBox.new, Gtk::VBox.new]
		
		index = 0
		@vboxes.each do |vbox|
			vbox.add(@buttonicons[index])
			vbox.add(@buttontext[index])
			@buttons[index].add(@vboxes[index])
			index += 1
		end
		@buttons.each{|button| @vbuttonbox1.pack_start(button,false,false)}
		@hbox1.pack_start(@vbuttonbox1,false,false,0) #pack the buttonbox into the mainwindow
		@gtk_window.add(@hbox1)
	end
	
	def create_signals
		@gtk_window.signal_connect("destroy") {savePreferences(); exit()}
		@gtk_window.signal_connect("delete_event") {savePreferences(); exit()}
		@buttons[0].signal_connect("activate") {@buttons[0].signal_emit("released")}
		@buttons[0].signal_connect("released") {savePreferences(); show_info()} # need this hack to keep the gui responsive
		@buttons[1].signal_connect("clicked") {savePreferences(); scan_drive()}
		@buttons[2].signal_connect("clicked") {savePreferences(); handle_tray()}
		@buttons[3].signal_connect("clicked") {savePreferences(); start_rip()}
		@buttons[4].signal_connect("clicked") {exitButton()}
	end
	
	def exitButton
		if @buttontext[4].text == _("Exit")
			savePreferences(); exit()
		else
			Thread.new do
				@rubyripper.cancelRip() # Let rubyripper stop ripping and encoding
				@rubyripper = nil # kill the instance
				@rubyripperThread.exit() # kill the thread
				@buttons.each{|button| button.sensitive = true}
				change_display(@instances['GtkMetadata'])
			end
		end
	end

	def cancelTocScan
		`killall cdrdao 2>&1`
	end

	def savePreferences
		if @current_instance == 'Preferences'
			@buttontext[0].set_text('_'+_('Preferences'),true)
			@buttonicons[0].stock = Gtk::Stock::PREFERENCES
			@instances['Preferences'].save #save any preferences when closing that window
		end
	end

	def exit
		`killall cdparanoia 2>&1`
		Gtk.main_quit
	end

	def change_display(object) #help function to manage the dynamic part of the window, the object is a class with a variable 'display' which contains everything
		# reset exit button
		if @current_instance == "RipStatus"
			@buttontext[4].set_text('_' + _("Exit"), true)
			@buttonicons[4].stock = Gtk::Stock::QUIT
		end

		unless @current_instance == false
			@hbox1.remove(@hbox1.children[-1])
		end
		
		@current_instance = object.class.to_s #the name of the instance type
		@hbox1.add(object.display)
		
		# update the Exit button to Abort button
		if @current_instance == "RipStatus"
			@buttontext[4].set_text('_' + _("Abort"), true)
			@buttonicons[4].stock = Gtk::Stock::CANCEL
		end

		object.display.show_all()
	end
	
	def welcome_message
		@instances['ShortMessage'] = ShortMessage.new(@settings['cdrom'])
		change_display(@instances['ShortMessage'])
	end

	def show_info
		@buttons.each{|button| button.sensitive = false}
		Thread.new do
			if @current_instance != 'Preferences'
				@buttontext[0].set_text('_'+_('Disc info'),true)
				@buttonicons[0].stock = Gtk::Stock::INFO
				unless @instances['Preferences'] ; @instances['Preferences'] = GtkSettings.new(@settings, @settingsClass) end
				@instances['Preferences'].display.page = 0
				change_display(@instances['Preferences'])
				@buttons[0..2].each{|button| button.sensitive = true} ; if @instances['GtkMetadata'] ; @buttons[3].sensitive = true end ; @buttons[4].sensitive = true
			elsif @instances['GtkMetadata']
				change_display(@instances['GtkMetadata'])
				@buttons.each{|button| button.sensitive = true}
			else
				scan_drive()
			end
		end
	end

	# give the cdrom drive a few seconds to read the disc
	def waitForDisc
		succes = false
		trial = 1

		while trial < 10
			@settings['cd'] = QuickScanDisc.new(@settings, self, 
				@settings.key?('cd') ? @settings['cd'].freedbString : '')
			if @settings['cd'].audiotracks != 0
				succes = true
				break
			else
				puts "No disc found at trial #{trial}!"
				sleep(1)
				trial += 1
			end
		end
		return succes
	end
	
	def scan_drive
		cancelTocScan()
		@buttons.each{|button| button.sensitive = false}
		Thread.new do
			# Analyze audio-cd, don't look at freedb yet. 
			#If the current freedb string is the same don't use yaml for metadata
			if waitForDisc() # if true, a cd is found
				if @buttontext[2].text != _("Open tray") # We know there's a cd inside so make sure that eject is shown instead of close tray
					@buttontext[2].set_text('_'+_("Open tray"),true)
					@buttonicons[2].stock = Gtk::Stock::GOTO_BOTTOM
				end	
				
				if @instances['GtkMetadata'] != false
					@instances['GtkMetadata'].refreshDisc(@settings['cd'])
				else
					@instances['GtkMetadata'] = GtkMetadata.new(@settings['cd']) #build the cdinfo for the gui
				end
				change_display(@instances['GtkMetadata']) #show this info on the display
				
				if @settings['freedb'] ; handleFreedb() end
				@buttons.each{|button| button.sensitive = true}
			else
				@instances['ShortMessage'].show_message(@settings['cd'].error)
				change_display(@instances['ShortMessage'])
				@buttons[0..2].each{|button| button.sensitive = true} ; @buttons[4].sensitive = true
			end
		end
	end

#Fetch the cddb info if user wants to
	def handleFreedb(choice = false)
		if choice == false
			@settings['cd'].md.freedb(@settings, @settings['first_hit'])
		elsif choice == -1
			@settings['cd'].md.freedbChoice(0)
		else
			@settings['cd'].md.freedbChoice(choice)
		end

		status = @settings['cd'].md.status
		
		if status == true #success
			@instances['GtkMetadata'].updateMetadata()
			if @current_instance != 'GtkMetadata'
				change_display(@instances['GtkMetadata'])
			end
		elsif status[0] == "choices"
			@instances['MultipleFreedbHits'] = MultipleFreedbHits.new(status[1], self)
			change_display(@instances['MultipleFreedbHits'])
		elsif status[0] == "networkDown" || status[0] == "noMatches" || status[0] == "unknownReturnCode" || status[0] == "NoAudioDisc"
			update("error", status[1])
		else
			puts "Unknown error with Metadata class."
		end
	end
	
	def handle_tray
		@buttons.each{|button| button.sensitive = false}
		Thread.new do
			if installed('eject')
				if @buttontext[2].text == _("Open tray")
					@instances['GtkMetadata'] = false
					@instances['ShortMessage'].open_tray(@settings['cdrom'])
					change_display(@instances['ShortMessage'])
					cancelTocScan()
					`eject #{@settings['cdrom']}` # spit the cd out
					@buttontext[2].set_text('_'+_("Close tray"),true)
					@buttonicons[2].stock = Gtk::Stock::GOTO_TOP
					@instances['ShortMessage'].ask_for_disc
					@buttons[0..2].each{|button| button.sensitive = true} ; @buttons[4].sensitive = true
				else
					@instances['ShortMessage'].close_tray(@settings['cdrom'])
					change_display(@instances['ShortMessage'])
					`eject --trayclose #{@settings['cdrom']}` # close the tray
					@buttontext[2].set_text('_'+_("Open tray"),true)
					@buttonicons[2].stock = Gtk::Stock::GOTO_BOTTOM
					scan_drive()
				end
 			else
 				@instances['ShortMessage'].no_eject_found
				change_display(@instances['ShortMessage'])
				@buttons[0..2].each{|button| button.sensitive = true} ; if @instances['GtkMetadata'] ; @buttons[3].sensitive = true end ; @buttons[4].sensitive = true
 			end
		end
	end
	
	def start_rip
		@buttons[0..3].each{|button| button.sensitive = false}
		@instances['GtkMetadata'].save_updates(@settings['image'])
		@settings['tracksToRip'] = @instances['GtkMetadata'].tracks_to_rip

		@rubyripper = Rubyripper.new(@settings, self) # start a new instance, keep it out the Thread for later callbacks (yet_to_implement)
		
		status = @rubyripper.settingsOk
		puts "status = #{status}" if @settings['debug']
		if status == true
			do_rip()
		else
			@buttons[0..3].each{|button| button.sensitive = true}
			update(status[0], status[1])
		end
	end
	
	def do_rip
		@rubyripperThread = Thread.new do
			@buttons[0..3].each{|button| button.sensitive = false}
			if @instances['RipStatus'] == false
				@instances['RipStatus'] = RipStatus.new()
			else
				@instances['RipStatus'].reset
			end

			change_display(@instances['RipStatus'])
			@rubyripper.startRip # fire away the start shot
		end
	end
	
	def showSummary(succes)
		@buttons[0..3].each{|button| button.sensitive = true}
		@instances['Summary'] = Summary.new(@settings['editor'], @settings['filemanager'], @rubyripper.outputDir, @rubyripper.summary, succes)
		change_display(@instances['Summary'])
		@instances['RipStatus'].reset()
		@rubyripper = false # some resetting of variables, I suspect some optimization of ruby otherwise would prevent refreshing
	end
	
	def update(modus, value=false)
		@updateThread.join if @updateThread != nil # one gui update at a time please
		@updateThread = Thread.new do
			if modus == "error"
				@instances['ShortMessage'].show_message(value)
				change_display(@instances['ShortMessage'])
				sleep(5)
				change_display(@instances['GtkMetadata'])
				@buttons.each{|button| button.sensitive = true}
			elsif modus == "ripping_progress"
				@instances['RipStatus'].updateProgress('ripping', value)
			elsif modus == "encoding_progress"
				@instances['RipStatus'].updateProgress('encoding', value)
			elsif modus == "log_change"
				@instances['RipStatus'].logChange(value)
			elsif modus == "dir_exists"
				@instances['DirExists'] = DirExists.new(self, @rubyripper, value)
				change_display(@instances['DirExists'])
			elsif modus == "finished"
				showSummary(value)
				if @settings['eject'] == true
					@buttontext[2].text =_("Close tray")
					@buttonicons[2].stock = Gtk::Stock::GOTO_TOP
				end
			else
				puts _("Ehh.. There shouldn't be anything else. WTF?")
				puts _("Secret modus = %s") % [modus]
			end
		end
	end
end

if __FILE__ == $0
	Gtk.init
	GraphicalUserInterface.new()
	Gtk.main
end
