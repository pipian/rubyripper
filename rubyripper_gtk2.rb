#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007  Bouke Woudstra (rubyripperdev@gmail.com)
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

class Main #the main window
attr_reader :change_display, :instances, :update

	def initialize
		@instances = {'Preferences' => false, 'GtkMetadata' => false, 'ShortMessage' => false, 'RipStatus' => false, 'DirExists' => false, 'MultipleFreedbHits' => false, 'Summary' => false}
		@current_instance = false
		@gtk_window = Gtk::Window.new('Rubyripper')
		ICONDIR.each{|dir| if File.exist?(file = File.join(dir, 'rubyripper.png')) : @gtk_window.icon = Gdk::Pixbuf.new(file) ; break end }
		@gtk_window.set_default_size(520, 400) #width, height
		
		@hbox1 = Gtk::HBox.new(false,5)

		create_buttonbox()
		create_signals()
		
		load_settings()
		welcome_message()
		
		@lock = Monitor.new()
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
		@buttons[4].signal_connect("clicked") {savePreferences(); exit()}
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
		unless @current_instance == false
			@hbox1.remove(@hbox1.children[-1])
		end
		
		@current_instance = object.class.to_s #the name of the instance type
		@hbox1.add(object.display)
		object.display.show_all()
	end
	
	def load_settings #first set default settings, then override them with custom settings if a config file is found
		@settings = $rr_defaultSettings
		
		if File.exist?(settingsfile = File.join(ENV['HOME'], '.rubyripper/settings'))
			file = File.new(settingsfile,'r')
			while line = file.gets
				key, value = line.split('=', 2)
				value.rstrip! # remove the trailing newline character
				if value == "false" : value = false # replace the string with a bool
				elsif value == "true" : value = true  # replace the string with a bool
				elsif value == "''" : value = '' #replace a string that contains two quotes with an empty string
				elsif value[0,1] == "#" : next #name of previous instances should not be loaded
				elsif value.to_i > 0 || value == '0' : value = value.to_i
				end
				if @settings.key?(key) : @settings[key] = value end
			end
			file.close()
		end
		if @settings['debug'] : Thread.abort_on_exception = true end
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
				unless @instances['Preferences'] : @instances['Preferences'] = Preferences.new(@settings) end
				@instances['Preferences'].display.page = 0
				change_display(@instances['Preferences'])
				@buttons[0..2].each{|button| button.sensitive = true} ; if @instances['GtkMetadata'] : @buttons[3].sensitive = true end ; @buttons[4].sensitive = true
			elsif @instances['GtkMetadata']
				change_display(@instances['GtkMetadata'])
				@buttons.each{|button| button.sensitive = true}
			else
				scan_drive()
			end
		end
	end
	
	def scan_drive
		@buttons.each{|button| button.sensitive = false}
		Thread.new do
			# Analyze audio-cd, don't look at freedb yet. If the current freedb string is the same don't use yaml for metadata
			@settings['cd'] = Disc.new(@settings['cdrom'], @settings['freedb'], self, @settings['verbose'], @settings.key?('cd') ? @settings['cd'].freedbString : '')

			if @settings['cd'].audiotracks != 0 # if true, a cd is found
				if @buttontext[2].text != _("Open tray") # We know there's a cd inside so make sure that eject is shown instead of close tray
					@buttontext[2].set_text('_'+_("Open tray"),true)
					@buttonicons[2].stock = Gtk::Stock::GOTO_BOTTOM
				end	
				@instances['GtkMetadata'] = GtkMetadata.new(@settings['cd']) #build the cdinfo for the gui
				change_display(@instances['GtkMetadata']) #show this info on the display
				
				if @settings['freedb'] : @settings['cd'].md.freedb(@settings, @settings['first_hit']) end #Fetch the cddb info if user wants to
				@buttons.each{|button| button.sensitive = true}
			else
				@instances['GtkMetadata'] = false
				@instances['ShortMessage'].show_message(@settings['cd'].error)
				change_display(@instances['ShortMessage'])
				@buttons[0..2].each{|button| button.sensitive = true} ; @buttons[4].sensitive = true
			end
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
				@buttons[0..2].each{|button| button.sensitive = true} ; if @instances['GtkMetadata'] : @buttons[3].sensitive = true end ; @buttons[4].sensitive = true
 			end
		end
	end
	
	def start_rip
		@buttons[0..3].each{|button| button.sensitive = false}
		@instances['GtkMetadata'].save_updates(@settings['image'])
		@settings['tracksToRip'] = @instances['GtkMetadata'].tracks_to_rip

		@rubyripper = Rubyripper.new(@settings, self) # start a new instance, keep it out the Thread for later callbacks (yet_to_implement)
		if @rubyripper.settings_ok # configuration check
			do_rip()
		else
			@buttons[0..3].each{|button| button.sensitive = true}
		end
	end
	
	def do_rip
		Thread.new do
			@buttons[0..3].each{|button| button.sensitive = false}
 			if @instances['RipStatus'] ==  false : @instances['RipStatus'] = RipStatus.new() else @instances['RipStatus'].reset end
			change_display(@instances['RipStatus'])
			@rubyripper.start_rip # fire away the start shot
		end
	end
	
	def showSummary
		@buttons[0..3].each{|button| button.sensitive = true}
		@instances['Summary'] = Summary.new(@settings['editor'], @settings['filemanager'], @rubyripper.output_dirs[0], @rubyripper.gui.short_summary)
		change_display(@instances['Summary'])
		@instances['RipStatus'].reset()
		@rubyripper = false # some resetting of variables, I suspect some optimization of ruby otherwise would prevent refreshing
	end
	
	def update(modus, value=false) #Threading here is not really necessary, because none of these are cpu intensive.
		Thread.new do
			if modus == "error"
				@instances['ShortMessage'].show_message(value)
				change_display(@instances['ShortMessage'])
				sleep(5)
				change_display(@instances['GtkMetadata'])
				@buttons.each{|button| button.sensitive = true}
			elsif modus == "cddb_hit" && !value
				@instances['GtkMetadata'].update()
				if @current_instance != 'GtkMetadata' : change_display(@instances['GtkMetadata']) end
			elsif modus == "cddb_hit" && value
				@instances['MultipleFreedbHits'] = MultipleFreedbHits.new(value, @settings['cd'], self)
				change_display(@instances['MultipleFreedbHits'])
			elsif modus == "ripping_progress"
				updateProgress('ripping', value)
			elsif modus == "encoding_progress"
				updateProgress('encoding', value)
			elsif modus == "log_change"
				@lock.synchronize do
					@instances['RipStatus'].textview.buffer.insert(@instances['RipStatus'].textview.buffer.end_iter, value) # First parameter is the last character + 1 in the log
					@instances['RipStatus'].textview.scroll_to_iter(@instances['RipStatus'].textview.buffer.end_iter, 0, true, 1, 1)
				end
			elsif modus == "dir_exists"
				@instances['DirExists'] = DirExists.new(self, @rubyripper, value)
				change_display(@instances['DirExists'])
			elsif modus == "finished"
				showSummary()
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

	def updateProgress(type, value)
		@lock.synchronize do
			progress = "%.3g" % (value * 100)
			if type == 'encoding'
				@instances['RipStatus'].enc_bar.text = _("Encoding progress %s \%") % [progress]
				@instances['RipStatus'].enc_bar.fraction = value
			else
				@instances['RipStatus'].rip_bar.text = _("Ripping progress %s \%") % progress
				@instances['RipStatus'].rip_bar.fraction = value
			end
		end
	end
end

class ShortMessage
attr_reader :display, :no_disc_found, :open_tray, :close_tray, :ask_for_disc, :no_eject_found, :show_message

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

class GtkMetadata
attr_reader :update, :display, :save_updates, :tracks_to_rip

	def initialize(cdinfo)
		@cd = cdinfo
		@tracks_to_rip = Array.new
		discinfo_objects() #create all necessary objects for displaying the discinfo
		trackselection_objects() #create all necessary objects for displaying the trackselection
		update()
		pack_both() #pack them together so we can show this beauty to the world :)
	end
	
	def discinfo_objects #helpfunction for show_cdinfo
		@table10 = Gtk::Table.new(3,4,false)
		@table10.column_spacings = 5
		@table10.row_spacings = 4
		@table10.border_width = 7
#create objects
		@artist_label = Gtk::Label.new(_('Artist:')) ; @artist_label.set_alignment(0.0, 0.5) ; @artist_entry = Gtk::Entry.new
		@album_label = Gtk::Label.new(_('Album:')) ; @album_label.set_alignment(0.0, 0.5) ; @album_entry = Gtk::Entry.new
		@genre_label = Gtk::Label.new(_('Genre:')) ; @genre_label.set_alignment(0.0, 0.5) ; @genre_entry = Gtk::Entry.new ; @genre_entry.width_request = 100
		@year_label = Gtk::Label.new(_('Year:')) ; @year_label.set_alignment(0.0, 0.5) ; @year_entry = Gtk::Entry.new ; @year_entry.width_request = 100
		@var_checkbox = Gtk::CheckButton.new(_('Mark disc as various artist'))
#add callback
		@var_checkbox.signal_connect("toggled") do
			if @var_checkbox.active? == true
				set_var_artist_in_table()
			else
				unset_var_artist_in_table()
			end
		end
#pack objects in 2x4 table
		@table10.attach(@artist_label, 0,1,0,1, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column
		@table10.attach(@album_label,0,1,1,2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table10.attach(@artist_entry, 1,2,0,1, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0,0) #2nd column
		@table10.attach(@album_entry, 1, 2, 1, 2, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0)
		@table10.attach(@genre_label, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #3rd column
		@table10.attach(@year_label, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table10.attach(@genre_entry, 3, 4, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 0) #4th column
		@table10.attach(@year_entry, 3 , 4, 1, 2, Gtk::SHRINK, Gtk::SHRINK, 0, 0)
		@table10.attach(@var_checkbox, 0, 4, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)		
	end
	
	def trackselection_objects #helpfunction for show_cdinfo
		@table20 = Gtk::Table.new(@cd.audiotracks + 1, 4, false)
		@table20.column_spacings = 5
		@table20.row_spacings = 4
		@table20.border_width = 7
#create objects and apply signals
		@all_tracks_button = Gtk::CheckButton.new(_('All')) ; @all_tracks_button.active = true #create checkbutton to select all/none tracks
		@check_track_array = Array.new ; @cd.audiotracks.times{|number| @check_track_array << Gtk::CheckButton.new((number + 1).to_s)} #create checkbutton for each track
		# Disable track selection buttons if we're ripping to a single file, it implies ripping the whole CD
#		if @settings['create_single_file'] == "true"
#			@check_track_array.each{|box| box.sensitive = false}
#		end
		@check_track_array.each{|tracknumber| tracknumber.active = true} #include all tracks by default
		@all_tracks_button.signal_connect("toggled") do
			@all_tracks_button.active? ? @check_track_array.each{|box| box.active = true} : @check_track_array.each{|box| box.active = false} #signal to toggle on/off all tracks 
		end
		@trackname_label = Gtk::Label.new(_("Tracknames \(%s tracks\)") % [@cd.audiotracks])
		@track_entry_array = Array.new ; @cd.audiotracks.times{@track_entry_array << Gtk::Entry.new}
		@length_label = Gtk::Label.new(_("Length \(%s\)") % [@cd.playtime])
		@length_label_array = Array.new ; @cd.audiotracks.times{|number| @length_label_array << Gtk::Label.new(@cd.lengthText[number])}
#pack objects in @cd.audiotracks + 1 by 3 table
		@table20.attach(@all_tracks_button, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 1st row
		@table20.attach(@trackname_label, 1, 3, 0, 1, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) #2nd + 3rd column (to later on allow various artist + trackname), 1st row
		@table20.attach(@length_label, 3, 4, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #4th column, 1st row
		@cd.audiotracks.times do |index|
			@table20.attach(@check_track_array[index], 0, 1, 1 + index, 2 + index, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 2nd row till end
			@table20.attach(@track_entry_array[index],1, 3, 1 + index, 2 + index, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) #2nd + 3rd column, 2nd row till end
			@table20.attach(@length_label_array[index],3, 4, 1 + index, 2 + index, Gtk::FILL, Gtk::SHRINK, 0, 0) #4th column, 2nd row till end
		end
	end

	def pack_both
#create frame for discinfo objects
		@label10 = Gtk::Label.new ; @label10.set_markup(_("<b>Disc info</b>"))
		@frame10 = Gtk::Frame.new
		@frame10.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame10.label_widget = @label10
		@frame10.border_width = 5
		@frame10.add(@table10)
#create scrolled window for trackselection_objects to allow for a lot of tracks
		@scrolled_window = Gtk::ScrolledWindow.new()
		@scrolled_window.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		@scrolled_window.set_border_width(5)
		@scrolled_window.add_with_viewport(@table20)
#create frame for trackselection_objects
		@label20 = Gtk::Label.new ; @label20.set_markup(_("<b>Track selection</b>"))
		@frame20 = Gtk::Frame.new()
		@frame20.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame20.label_widget = @label20
		@frame20.border_width = 5
		@frame20.add(@scrolled_window)
#move both frames into a vbox
		@display = Gtk::VBox.new #One VBox to rule them all
		@display.pack_start(@frame10, false, false)
		@display.pack_start(@frame20, true, true)
	end	
	
	def update() # Update gui with freedb info
		if not @cd.md.varArtists.empty? : @var_checkbox.active = true end
		@artist_entry.text = @cd.md.artist ; @album_entry.text = @cd.md.album
		@year_entry.text = @cd.md.year ; @genre_entry.text = @cd.md.genre
		@cd.audiotracks.times{|index| @track_entry_array[index].text = @cd.md.tracklist[index]}
		unless @cd.md.varArtists.empty? : set_var_artist_in_table() end
	end

	def set_var_artist_in_table
		@cd.audiotracks.times{|time| if @cd.md.varArtists[time] == nil:  @cd.md.varArtists[time] = _('Unknown') end} #Fill with unknown if the artistfield is not there
		if @table20.children.include?(@var_artist_label) : @table20.remove(@var_artist_label) ; @var_artist_array.each{|object| @table20.remove(object)} end #remove the previous 
		@var_artist_label = Gtk::Label.new(_('Artist'))
		@var_artist_array = Array.new ; @cd.audiotracks.times{|index| @var_artist_array << Gtk::Entry.new}
		@cd.audiotracks.times{|index| @var_artist_array[index].text = @cd.md.varArtists[index]}
		#remove current tracknames from array, as we're repacking them
		@table20.remove(@trackname_label) ; @track_entry_array.each{|object| @table20.remove(object)}
		#repack into @table20
		@table20.attach(@var_artist_label, 1, 2, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column, 1st row
		@table20.attach(@trackname_label, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #3rd column, 1st row
		@cd.audiotracks.times do |index|
			@table20.attach(@var_artist_array[index], 1, 2, index + 1, index + 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
			@table20.attach(@track_entry_array[index], 2, 3, index + 1, index + 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		end
		@table20.show_all()
	end

	def unset_var_artist_in_table
		@cd.md.undoVarArtist() #sets the names back
		if @table20.children.include?(@var_artist_label)
			@table20.remove(@var_artist_label)
			@var_artist_array.each{|object| @table20.remove(object)}
		end
		@table20.remove(@trackname_label) ; @track_entry_array.each{|object| @table20.remove(object)}

		@table20.attach(@trackname_label, 1, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #3rd column, 1st row
		@cd.audiotracks.times do |index|
			@table20.attach(@track_entry_array[index], 1, 3, index + 1, index + 2, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0)
		end
		update() #get the updated info before displaying
		@table20.show_all()
	end
	
	def save_updates(image=false) # save all updated info from the user
		@cd.md.artist = @artist_entry.text
		@cd.md.album = @album_entry.text
		@cd.md.genre = @genre_entry.text
		@cd.md.year = @year_entry.text if @year_entry.text.to_i != 0
		
		@tracks_to_rip = Array.new #reset the array
		
		if image
		    @tracks_to_rip = [0]
		else
		    @cd.audiotracks.times do |index|
			@cd.md.tracklist[index] = @track_entry_array[index].text
			if @check_track_array[index].active? : @tracks_to_rip << index + 1 end
		    end
		end
		
		unless @cd.md.varArtists.empty?
			@cd.audiotracks.times{|index| @cd.md.varArtists[index] = @var_artist_array[index].text}
		end
	end
end

class Preferences
attr_reader :display, :save

	def initialize(settings)
		@settings = settings
		@display = Gtk::Notebook.new # Create a notebook (multiple pages)
		ripobjects_frame1()
		ripobjects_frame2()
		ripobjects_frame3()
		codecobjects_frame1()
		codecobjects_frame2()
		codecobjects_frame3()
		freedbobjects_frame()
		otherobjects_frame1()
		otherobjects_frame2()
		otherobjects_frame3()
		pack_other_frames()
		load()
	end
	
	def load # load the settings
#ripping settings
		@cdrom_entry.text = @settings['cdrom']
		@cdrom_offset_spin.value = @settings['offset'].to_f
		@all_chunks_spin.value = @settings['req_matches_all'].to_f
		@err_chunks_spin.value = @settings['req_matches_errors'].to_f
		@max_spin.value = @settings['max_tries'].to_f
		@rip_entry.text = @settings['rippersettings']
		@eject.active = @settings['eject']
		@no_log.active = @settings['no_log']
		@create_cue.active = @settings['create_cue']
		@create_single_file.active = @settings['image']
#codec settings
		@flac.active = @settings['flac']
		@vorbis.active = @settings['vorbis']
		@mp3.active = @settings['mp3']
		@wav.active = @settings['wav']
		@other.active = @settings['other']
		@flac_entry.text = @settings['flacsettings']
		@vorbis_entry.text = @settings['vorbissettings']
		@mp3_entry.text = @settings['mp3settings']
		@other_entry.text = @settings['othersettings']
		@playlist.active = @settings['playlist']
		@maxThreads.value = @settings['maxThreads'].to_f
		@normalize.active = if @settings['normalize'] == false : 0 elsif @settings['normalize'] == "replaygain" : 1 else 2 end
		@modus.active = if @settings['gain'] == "album" : 0 else 1 end
#freedb
		@enable_freedb.active = @settings['freedb']
		@first_hit.active = @settings['first_hit']
		@freedb_server_entry.text = @settings['site']
		@freedb_username_entry.text = @settings['username']
		@freedb_hostname_entry.text = @settings['hostname']
#other
		@basedir_entry.text = @settings['basedir']
		@naming_normal_entry.text = @settings['naming_normal']
		@naming_various_entry.text = @settings['naming_various']
		@naming_image_entry.text = @settings['naming_image']
		@verbose.active = @settings['verbose']
		@debug.active = @settings['debug']
		@editor_entry.text = @settings['editor']
		@filemanager_entry.text = @settings['filemanager']
	end
	
	def save # Update the settings hash from the preferences window
#ripping settings
		@settings['cdrom'] = @cdrom_entry.text
		@settings['offset'] = @cdrom_offset_spin.value.to_i
		@settings['req_matches_all'] = @all_chunks_spin.value.to_i
		@settings['req_matches_errors'] = @err_chunks_spin.value.to_i
		@settings['max_tries'] = @max_spin.value.to_i
		@settings['rippersettings'] = @rip_entry.text
		@settings['eject'] = @eject.active?
		@settings['no_log'] = @no_log.active?
		@settings['create_cue'] = @create_cue.active?
		@settings['image'] = @create_single_file.active?
#codec settings
		@settings['flac'] = @flac.active?
		@settings['vorbis'] = @vorbis.active?
		@settings['mp3'] = @mp3.active?
		@settings['wav'] = @wav.active?
		@settings['other'] = @other.active?
		@settings['flacsettings'] = @flac_entry.text
		@settings['vorbissettings'] = @vorbis_entry.text
		@settings['mp3settings'] = @mp3_entry.text
		@settings['othersettings'] = @other_entry.text
		@settings['playlist'] = @playlist.active?
		@settings['maxThreads'] = @maxThreads.value.to_i
		@settings['normalize'] = if @normalize.active == 0 : false elsif @normalize.active == 1 : "replaygain" else "normalize" end
		@settings['gain'] = if @modus.active ==0 : "album" else "track" end
#freedb
		@settings['freedb'] = @enable_freedb.active?
		@settings['first_hit'] = @first_hit.active?
		@settings['site'] = @freedb_server_entry.text
		@settings['username'] = @freedb_username_entry.text
		@settings['hostname'] = @freedb_hostname_entry.text
#other
		@settings['basedir'] = @basedir_entry.text
		@settings['naming_normal'] = @naming_normal_entry.text
		@settings['naming_various'] = @naming_various_entry.text
		@settings['naming_image'] = @naming_image_entry.text
		@settings['verbose'] = @verbose.active?
		@settings['debug'] = @debug.active?
		@settings['editor'] = @editor_entry.text
		@settings['filemanager'] = @filemanager_entry.text
		if @settings['debug'] : Thread.abort_on_exception = true end
		save_configfile() #also update the config file
	end
	
	def save_configfile
		if not File.directory?(dirname = File.join(ENV['HOME'], '.rubyripper')) : Dir.mkdir(dirname) end
		file = File.new(File.join(ENV['HOME'], '.rubyripper/settings'), 'w')
		@settings.each do |key, value|
			file.puts "#{key}=#{value}"
		end
		file.close()
	end
	
#Today is a great day to start counting with 40 :) Actually I worked backwards and needed to make sure I had enough room in the beginning.
	def ripobjects_frame1 # Cdrom device frame
		@table40 = Gtk::Table.new(3,2,false)
		@table40.column_spacings = 5
		@table40.row_spacings = 4
		@table40.border_width = 7
#creating objects
		@cdrom_label = Gtk::Label.new(_("Cdrom device:")) ; @cdrom_label.set_alignment(0.0, 0.5) # Align to the left instead of center
		@cdrom_offset_label = Gtk::Label.new(_("Cdrom offset:")) ; @cdrom_offset_label.set_alignment(0.0, 0.5)
		@cdrom_entry = Gtk::Entry.new ; @cdrom_entry.width_request = 120
		@cdrom_offset_spin = Gtk::SpinButton.new(-1500.0, 1500.0, 1.0) ; @cdrom_offset_spin.value = 0.0
		@offset_button = Gtk::LinkButton.new(_('List with offsets')) ; @offset_button.uri = "http://www.accuraterip.com/driveoffsets.htm"
		@offset_button.tooltip_text = _("A website which lists the offset for most drives.\nYour drivename can be found in each logfile.")
#pack objects
		@table40.attach(@cdrom_label, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table40.attach(@cdrom_offset_label, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table40.attach(@cdrom_entry, 1, 2, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 0)
		@table40.attach(@cdrom_offset_spin, 1, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table40.attach(@offset_button, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
#connect signal
		@offset_button.signal_connect("clicked") {Thread.new{`#{browser()} #{@offset_button.uri}`}}
#create frame
		@frame40 = Gtk::Frame.new(_('Cdrom device'))
		@frame40.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame40.border_width = 5
		@frame40.add(@table40)
	end
	
	def ripobjects_frame2 # Ripping options frame
		@table50 = Gtk::Table.new(3,3,false)
		@table50.column_spacings = 5
		@table50.row_spacings = 4
		@table50.border_width = 7
#create objects
		@all_chunks = Gtk::Label.new(_("Match all chunks:")) ; @all_chunks.set_alignment(0.0, 0.5)
		@err_chunks = Gtk::Label.new(_("Match erroneous chunks:")) ; @err_chunks.set_alignment(0.0, 0.5)
		@max_label = Gtk::Label.new(_("Maximum trials (0 = unlimited):")) ; @max_label.set_alignment(0.0, 0.5)
		@all_chunks_spin = Gtk::SpinButton.new(2.0,  100.0, 1.0)
		@err_chunks_spin = Gtk::SpinButton.new(2.0, 100.0, 1.0)
		@max_spin = Gtk::SpinButton.new(0.0, 100.0, 1.0)
		@time1 = Gtk::Label.new(_("times"))
		@time2 = Gtk::Label.new(_("times"))
		@time3 = Gtk::Label.new(_("times"))
#pack objects
		@table50.attach(@all_chunks, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column
		@table50.attach(@err_chunks, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table50.attach(@max_label, 0, 1, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table50.attach(@all_chunks_spin, 1, 2, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column
		@table50.attach(@err_chunks_spin, 1, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table50.attach(@max_spin, 1, 2, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table50.attach(@time1, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #3rd column
		@table50.attach(@time2, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table50.attach(@time3, 2, 3, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
#connect a signal to @all_chunks to make sure @err_chunks get always at least the same amount of rips as @all_chunks
		@all_chunks_spin.signal_connect("value_changed") {if @err_chunks_spin.value < @all_chunks_spin.value : @err_chunks_spin.value = @all_chunks_spin.value end ; @err_chunks_spin.set_range(@all_chunks_spin.value,100.0)} #ensure all_chunks cannot be smaller that err_chunks.
#create frame
		@frame50= Gtk::Frame.new(_('Ripping options'))
		@frame50.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame50.border_width = 5
		@frame50.add(@table50)
	end
	
	def ripobjects_frame3 #Ripping related frame
		@table60 = Gtk::Table.new(4,3,false)
		@table60.column_spacings = 5
		@table60.row_spacings = 4
		@table60.border_width = 7
#create objects
		@rip_label = Gtk::Label.new(_("Pass cdparanoia options:")) ; @rip_label.set_alignment(0.0, 0.5)
		@eject= Gtk::CheckButton.new(_('Eject cd when finished'))
		@no_log = Gtk::CheckButton.new(_('Only keep logfile if correction is needed'))
		@create_cue = Gtk::CheckButton.new(_('Create cuesheet'))
		@create_single_file = Gtk::CheckButton.new(_('Rip CD to single file'))
		@rip_entry= Gtk::Entry.new ; @rip_entry.width_request = 120
#pack objects
		@table60.attach(@rip_label, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table60.attach(@eject, 0, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table60.attach(@rip_entry, 1, 2, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 0)
		@table60.attach(@no_log, 0, 2, 2, 3, Gtk::FILL|Gtk::SHRINK, Gtk::SHRINK, 0, 0)
		@table60.attach(@create_cue, 0, 2, 3, 4, Gtk::FILL|Gtk::SHRINK, Gtk::SHRINK, 0, 0)
		@table60.attach(@create_single_file, 0, 2, 4, 5, Gtk::FILL|Gtk::SHRINK, Gtk::SHRINK, 0, 0)
#create frame
		@frame60 = Gtk::Frame.new(_('Ripping related'))
		@frame60.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame60.border_width = 5
		@frame60.add(@table60)
#pack all frames into a single page
		@page1 = Gtk::VBox.new #One VBox to rule them all
		[@frame40, @frame50, @frame60].each{|frame| @page1.pack_start(frame,false,false)}
		@page1_label = Gtk::Label.new(_("Secure Ripping"))
		@display.append_page(@page1, @page1_label)
	end
	
	def codecobjects_frame1 # Select audio codecs frame
		@table70 = Gtk::Table.new(6,2,false)
		@table70.column_spacings = 5
		@table70.row_spacings = 4
		@table70.border_width = 7
#objects 1st column
		@flac = Gtk::CheckButton.new(_('Flac'))
		@vorbis = Gtk::CheckButton.new(_('Vorbis'))
		@mp3=  Gtk::CheckButton.new(_('Lame Mp3'))
		@wav = Gtk::CheckButton.new(_('Wav'))
		@other = Gtk::CheckButton.new(_('Other'))
		@expander70 = Gtk::Expander.new(_('Show options for "Other"'))
#objects 2nd column
		@flac_entry= Gtk::Entry.new()
		@vorbis_entry= Gtk::Entry.new()
		@mp3_entry= Gtk::Entry.new()
		@other_entry= Gtk::Entry.new()
#fill expander
		@legend = Gtk::Label.new(_("%a=artist   %g=genre   %t=trackname   %f=codec\n%b=album   %y=year   %n=track   %va=various artist\n%o = outputfile   %i = inputfile"))
		@expander70.add(@legend)
#pack_objects
		@table70.attach(@flac, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 1st row
		@table70.attach(@vorbis, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 2nd row
		@table70.attach(@mp3, 0, 1, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 3rd row
		@table70.attach(@wav, 0, 2, 3, 4, Gtk::FILL, Gtk::SHRINK, 0, 0) #both columns, 4th row
		@table70.attach(@other, 0, 1, 4, 5, Gtk::FILL, Gtk::SHRINK, 0, 0) # 1st column, 5th row
		@table70.attach(@expander70, 0, 2, 5, 6, Gtk::FILL, Gtk::SHRINK, 0, 0) #both columns, 6th row
		@table70.attach(@flac_entry, 1, 2, 0, 1, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) #2nd column, 1st row
		@table70.attach(@vorbis_entry, 1, 2, 1, 2, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) #2nd column, 2nd row
		@table70.attach(@mp3_entry, 1, 2, 2, 3, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) # 2nd column, 3rd row
		@table70.attach(@other_entry, 1, 2, 4, 5, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) # 2nd column, 5th row
#create frame
		@frame70 = Gtk::Frame.new(_("Select audio codecs"))
		@frame70.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame70.border_width = 5
		@frame70.add(@table70) # add the hbox in the frame
	end
	
	def codecobjects_frame2 #Encoding related frame
		@table80 = Gtk::Table.new(2,2,false)
		@table80.column_spacings = 5
		@table80.row_spacings = 4
		@table80.border_width = 7
#creating objects
		@playlist = Gtk::CheckButton.new(_("Create m3u playlist"))
		@maxThreads = Gtk::SpinButton.new(0.0, 10.0, 1.0)
		@maxThreadsLabel = Gtk::Label.new(_("Number of extra encoding threads"))
#packing objects
		@table80.attach(@playlist, 0, 2, 0, 1, Gtk::FILL, Gtk::FILL, 0, 0)
		@table80.attach(@maxThreadsLabel, 0, 1, 1, 2, Gtk::FILL, Gtk::FILL, 0, 0)
		@table80.attach(@maxThreads, 1, 2, 1, 2, Gtk::FILL, Gtk::FILL, 0, 0)
#create frame
		@frame80 = Gtk::Frame.new(_("Codec related"))
		@frame80.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame80.border_width = 5
		@frame80.add(@table80)
	end

	def codecobjects_frame3 #Normalize audio
		@table85 = Gtk::Table.new(2,1,false)
		@table85.column_spacings = 5
		@table85.row_spacings = 4
		@table85.border_width = 7
#creating objects
		@normalize = Gtk::ComboBox.new()
		@normalize.append_text(_("Don't standardize volume"))
		@normalize.append_text(_("Use replaygain on audio files"))
		@normalize.append_text(_("Use normalize on wav files"))
		@normalize.active=0
		@modus = Gtk::ComboBox.new()
		@modus.append_text(_("Album / Audiophile modus"))
		@modus.append_text(_("Track modus"))
		@modus.active = 0
		@modus.sensitive = false
		@normalize.signal_connect("changed") {if @normalize.active == 0 : @modus.sensitive = false else @modus.sensitive = true end}
#packing objects
		@table85.attach(@normalize, 0, 1, 0, 1, Gtk::FILL, Gtk::FILL, 0, 0)
		@table85.attach(@modus, 1, 2, 0, 1, Gtk::FILL, Gtk::FILL, 0, 0)
#create frame
		@frame85 = Gtk::Frame.new(_("Normalize to standard volume"))
		@frame85.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame85.border_width = 5
		@frame85.add(@table85)
#pack all frames into a single page
		@page2 = Gtk::VBox.new #One VBox to rule them all
		[@frame70, @frame80, @frame85].each{|frame| @page2.pack_start(frame,false,false)}
		@page2_label = Gtk::Label.new(_("Codecs"))
		@display.append_page(@page2, @page2_label)
	end
	
	def freedbobjects_frame #Freedb client configuration frame
		@table90 = Gtk::Table.new(5,2,false)
		@table90.column_spacings = 5
		@table90.row_spacings = 4
		@table90.border_width = 7
#creating objects
		@enable_freedb= Gtk::CheckButton.new(_("Enable freedb metadata fetching"))
		@first_hit= Gtk::CheckButton.new(_("Always use first freedb hit"))
		@freedb_server_label= Gtk::Label.new(_("Freedb server:")) ; @freedb_server_label.set_alignment(0.0, 0.5)
		@freedb_username_label= Gtk::Label.new(_("Username:")) ; @freedb_username_label.set_alignment(0.0, 0.5)
		@freedb_hostname_label= Gtk::Label.new(_("Hostname:")) ; @freedb_hostname_label.set_alignment(0.0, 0.5)
		@freedb_server_entry = Gtk::Entry.new
		@freedb_username_entry = Gtk::Entry.new
		@freedb_hostname_entry = Gtk::Entry.new
#packing objects
		@table90.attach(@enable_freedb, 0, 2, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #both columns, 1st row
		@table90.attach(@first_hit, 0, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0) #both columns, 2nd row
		@table90.attach(@freedb_server_label, 0, 1, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 3rd row
		@table90.attach(@freedb_username_label, 0, 1, 3, 4, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 4th row
		@table90.attach(@freedb_hostname_label, 0, 1, 4, 5, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 5th row
		@table90.attach(@freedb_server_entry, 1, 2 , 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column, 3rd row
		@table90.attach(@freedb_username_entry, 1, 2, 3, 4, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column, 4th row
		@table90.attach(@freedb_hostname_entry, 1, 2, 4, 5, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column, 5th row
#create frame
		@frame90 = Gtk::Frame.new(_("Freedb options")) # will contain the above
		@frame90.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame90.border_width = 5
		@frame90.add(@table90)
#pack frame
		@page3 = Gtk::VBox.new #One VBox to rule them all
		[@frame90].each{|frame| @page3.pack_start(frame,false,false)}
		@page3_label = Gtk::Label.new(_("Freedb"))
		@display.append_page(@page3, @page3_label)
	end

	def otherobjects_frame1 # Naming scheme frame
		@table100 = Gtk::Table.new(6,2,false)
		@table100.column_spacings = 5
		@table100.row_spacings = 4
		@table100.border_width = 7
#creating objects 1st column
		@basedir_label = Gtk::Label.new(_('Base directory:')) ; @basedir_label.set_alignment(0.0, 0.5) #set_alignment(xalign=0.0, yalign=0.5)
		@naming_normal_label = Gtk::Label.new(_('Standard:')) ; @naming_normal_label.set_alignment(0.0, 0.5)
		@naming_various_label = Gtk::Label.new(_('Various artists:')) ; @naming_various_label.set_alignment(0.0, 0.5)
		@naming_image_label = Gtk::Label.new(_('Single file image:')) ; @naming_image_label.set_alignment(0.0, 0.5)
		@example_label =Gtk::Label.new('') ; @example_label.set_alignment(0.0, 0.5) ; @example_label.wrap = true
		@expander100 = Gtk::Expander.new(_('Show options for "Filenaming scheme"'))
#configure expander
		#@artist_label = Gtk::Label.new("%a = artist   %b = album   %f = codec   %g = genre\n%va = various artists   %n = track   %t = trackname   %y = year")
		@legend_label = Gtk::Label.new(_("%a=artist   %g=genre   %t=trackname   %f=codec\n%b=album   %y=year   %n=track   %va=various artist"))
		@expander100.add(@legend_label)
#packing 1st column
		@table100.attach(@basedir_label, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table100.attach(@naming_normal_label, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table100.attach(@naming_various_label, 0, 1, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table100.attach(@naming_image_label, 0, 1, 3, 4, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table100.attach(@example_label, 0, 2, 4, 5, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0) #width = 2 columns, also maximise width
		@table100.attach(@expander100, 0, 2 , 5, 6, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0)
#creating objects 2nd column and connect signals to them
		@basedir_entry = Gtk::Entry.new
		@naming_normal_entry = Gtk::Entry.new
		@naming_various_entry = Gtk::Entry.new
		@naming_image_entry = Gtk::Entry.new
		@basedir_entry.signal_connect("key_release_event"){@example_label.text = get_example_filename_normal(@basedir_entry.text, @naming_normal_entry.text) ; false}
		@basedir_entry.signal_connect("button_release_event"){@example_label.text = get_example_filename_normal(@basedir_entry.text, @naming_normal_entry.text) ; false}
		@naming_normal_entry.signal_connect("key_release_event"){@example_label.text = get_example_filename_normal(@basedir_entry.text, @naming_normal_entry.text) ; false}
		@naming_normal_entry.signal_connect("button_release_event"){@example_label.text = get_example_filename_normal(@basedir_entry.text, @naming_normal_entry.text) ; false}
		@naming_various_entry.signal_connect("key_release_event"){@example_label.text = get_example_filename_various(@basedir_entry.text, @naming_various_entry.text) ; false}
		@naming_various_entry.signal_connect("button_release_event"){@example_label.text = get_example_filename_various(@basedir_entry.text, @naming_various_entry.text) ; false}
		@naming_image_entry.signal_connect("key_release_event"){@example_label.text = get_example_filename_various(@basedir_entry.text, @naming_image_entry.text) ; false}
		@naming_image_entry.signal_connect("button_release_event"){@example_label.text = get_example_filename_various(@basedir_entry.text, @naming_image_entry.text) ; false}
#packing 2nd column
		@table100.attach(@basedir_entry, 1, 2, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table100.attach(@naming_normal_entry, 1, 2, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table100.attach(@naming_various_entry, 1, 2, 2, 3, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table100.attach(@naming_image_entry, 1, 2, 3, 4, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0)
#create frame
		@frame100 = Gtk::Frame.new(_("Filenaming scheme")) #will contain the above
		@frame100.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame100.border_width = 5
		@frame100.add(@table100)
	end

#Small table needed for setting programs
#log file viewer 	| entry
#file manager 	| entry
	def otherobjects_frame2
		@table110 = Gtk::Table.new(2,2,false)
		@table110.column_spacings = 5
		@table110.row_spacings = 4
		@table110.border_width = 7
#creating objects
		@editor_label = Gtk::Label.new(_("Log file viewer: ")) ; @editor_label.set_alignment(0.0, 0.5)
		@filemanager_label = Gtk::Label.new(_("File manager: ")) ; @filemanager_label.set_alignment(0.0,0.5)
		@editor_entry = Gtk::Entry.new
		@filemanager_entry = Gtk::Entry.new
#packing objects
		@table110.attach(@editor_label, 0,1,0,1,Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table110.attach(@filemanager_label, 0,1,1,2,Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table110.attach(@editor_entry, 1,2,0,1, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table110.attach(@filemanager_entry, 1,2,1,2, Gtk::FILL, Gtk::SHRINK, 0, 0)
#create frame
		@frame110 = Gtk::Frame.new(_("Programs of choice"))
		@frame110.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame110.border_width = 5
		@frame110.add(@table110)
	end

#Small table for debugging
#Verbose mode	| debug mode	
	def otherobjects_frame3 # Debug options frame
		@table120 = Gtk::Table.new(1,2,false)
		@table120.column_spacings = 5
		@table120.row_spacings = 4
		@table120.border_width = 7
#creating objects and packing them
		@verbose = Gtk::CheckButton.new(_('Verbose mode'))
		@debug = Gtk::CheckButton.new(_('Debug mode'))
		@table120.attach(@verbose, 0,1,0,1,Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK)
		@table120.attach(@debug, 1,2,0,1,Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK)
#create frame
		@frame120 = Gtk::Frame.new(_("Debug options")) #will contain the above
		@frame120.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame120.border_width = 5
		@frame120.add(@table120)
	end
	
	def pack_other_frames #pack all frames into a single page
		@page4 = Gtk::VBox.new()
		[@frame100, @frame110, @frame120].each{|frame| @page4.pack_start(frame,false,false)}
		@page4_label = Gtk::Label.new(_("Other"))
		@display.signal_connect("switch_page"){|a, b, page| if page == 3: @example_label.text = get_example_filename_normal(@basedir_entry.text, @naming_normal_entry.text) end}
		@display.append_page(@page4, @page4_label)
	end
end

class RipStatus
attr_reader :textview, :rip_bar, :enc_bar, :display, :reset

	def initialize
		create_status_objects()
		pack_status_objects()
		reset() #reset to default text
	end
	
	def create_status_objects
		@textview = Gtk::TextView.new
		@textview.editable = false
		@textview.wrap_mode = Gtk::TextTag::WRAP_WORD
		@scrolled_window = Gtk::ScrolledWindow.new
		@scrolled_window.set_policy(Gtk::POLICY_NEVER,Gtk::POLICY_AUTOMATIC)
		@scrolled_window.border_width = 7
		@scrolled_window.add(@textview)
		
		@enc_bar = Gtk::ProgressBar.new
 		@rip_bar = Gtk::ProgressBar.new
		@enc_bar.pulse_step = 0.01
 		@rip_bar.pulse_step = 0.01
		
		@hbox1 = Gtk::HBox.new(true,5)
		@vbox1 = Gtk::VBox.new(false,5)
		@vbox1.border_width = 5
		
		@label1 = Gtk::Label.new
 		@label1.set_markup(_("<b>Ripping status</b>"))
		@display = Gtk::Frame.new
		@display.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@display.label_widget = @label1
		@display.border_width = 5
	end
	
	def pack_status_objects
		@hbox1.pack_start(@rip_bar)
		@hbox1.pack_start(@enc_bar)
		@vbox1.pack_start(@scrolled_window)
		@vbox1.pack_start(@hbox1,false,false)
		@display.add(@vbox1)
	end
	
	def reset # load default values
		@enc_bar.text = _('Not yet started (0%)')
 		@rip_bar.text = _('Not yet started (0%)')
 		@enc_bar.fraction = 0.0
 		@rip_bar.fraction = 0.0
 		@textview.buffer.text = ""
	end
end

class DirExists
attr_reader :display

	def initialize(gui, rubyripper, dirname)
		@label = Gtk::Label.new(_("The directory %s\nalready exist. What do you want rubyripper to do?") % [dirname])
		@label.wrap = true
		@image = Gtk::Image.new(Gtk::Stock::DIALOG_QUESTION, Gtk::IconSize::DIALOG)
		
		@infobox = Gtk::HBox.new
		@infobox.add(@image) ; @infobox.add(@label)
		@separator = Gtk::HSeparator.new

		@buttons = [Gtk::Button.new, Gtk::Button.new, Gtk::Button.new]
		@labels = [Gtk::Label.new(_("Cancel rip")), Gtk::Label.new(_("Overwrite\ndirectory")), Gtk::Label.new(_("Auto rename\ndirectory"))]
		@images = [Gtk::Image.new(Gtk::Stock::CANCEL, Gtk::IconSize::LARGE_TOOLBAR), Gtk::Image.new(Gtk::Stock::CLEAR, Gtk::IconSize::LARGE_TOOLBAR), Gtk::Image.new(Gtk::Stock::OK, Gtk::IconSize::LARGE_TOOLBAR)]
		@hboxes = [Gtk::HBox.new, Gtk::HBox.new, Gtk::HBox.new]
		@buttonbox = Gtk::HBox.new
		
		3.times do |index|
			@hboxes[index].pack_start(@images[index], false, false) #pack the image + label into a hbox
			@hboxes[index].pack_start(@labels[index], false, false)
			@buttons[index].add(@hboxes[index]) #put the hbox into the button
			@buttonbox.pack_start(@buttons[index], false, false, 10) #put the buttons into a hbox
		end
		
		@buttons[0].signal_connect("released") {gui.change_display(gui.instances['GtkMetadata'])}
		@buttons[1].signal_connect("released") {rubyripper.overwrite_dir() ; gui.do_rip() }
		@buttons[2].signal_connect("released") {rubyripper.postfix_dir() ; gui.do_rip() }

		@vbox = Gtk::VBox.new
		@vbox.border_width = 10
		[@infobox, @separator, @buttonbox].each{|object| @vbox.pack_start(object,false,false,10)}
		
		@display = Gtk::Frame.new(_("Dir already exists...")) # will contain the above
		@display.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@display.border_width = 5
		@display.add(@vbox)
	end
end
		
class MultipleFreedbHits
attr_reader :display

	def initialize(value, cd, main_instance)
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
				if @combobox.active == -1 : cd.md.freedbChoice(0) else cd.md.freedbChoice(@combobox.active) end
			end
		end
	end
end

class Summary
attr_reader :display

	def initialize(editor, filemanager, directory, summary)
		@label1 = Gtk::Label.new(_("Rubyripper is finished with ripping the cd.\nA short summary is shown below."))
		@image1 = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
		@hbox1 = Gtk::HBox.new()
		[@image1, @label1].each{|object| @hbox1.pack_start(object)}
		@hbox1.border_width = 10
		@separator1 = Gtk::HSeparator.new
		
		@textview = Gtk::TextView.new
		@textview.editable = false
		@scrolled_window = Gtk::ScrolledWindow.new
		@scrolled_window.set_policy(Gtk::POLICY_NEVER, Gtk::POLICY_NEVER)
		@scrolled_window.border_width = 7
		@scrolled_window.add(@textview)
		@textview.buffer.insert(@textview.buffer.end_iter, summary)
				
		@button1 = Gtk::Button.new()
		@label2 = Gtk::Label.new(_("Open log file"))
		@image2 = Gtk::Image.new(Gtk::Stock::EXECUTE, Gtk::IconSize::LARGE_TOOLBAR)
		@hbox2 = Gtk::HBox.new()
		[@image2, @label2].each{|object| @hbox2.pack_start(object)}
		@button1.add(@hbox2)
		@button1.signal_connect("released"){Thread.new{if installed(editor.split()[0]) : `#{editor} "#{directory + '/ripping.log'}"` else puts _("%s is not found on your system!") % [editor.split()[0]] end}}
		
		@button2 = Gtk::Button.new()
		@label3 = Gtk::Label.new(_("Open directory"))
		@image3 = Gtk::Image.new(Gtk::Stock::OPEN, Gtk::IconSize::LARGE_TOOLBAR)
		@hbox3 = Gtk::HBox.new()
		[@image3, @label3].each{|object| @hbox3.pack_start(object)}
		@button2.add(@hbox3)
		@button2.signal_connect("released"){Thread.new{if installed(filemanager.split()[0]) : `#{filemanager} "#{directory}"` else puts _("%s is not found on your system!") % [filemanager.split()[0]] end}}
		
		@hbox4 = Gtk::HBox.new(true, 5) #put the two buttons in a box
		[@button1, @button2].each{|object| @hbox4.pack_start(object)}
		
		@vbox1 = Gtk::VBox.new(false,10)
		@vbox1.pack_start(@hbox1,false,false)
		@vbox1.pack_start(@separator1,false,false)
		@vbox1.pack_start(@scrolled_window,false,false) #maximize the space for displaying the tracks
		@vbox1.pack_start(@hbox4,false,false)
		
		@display = Gtk::Frame.new(_("Ripping and encoding is finished"))
		@display.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@display.border_width = 5
		@display.add(@vbox1)
	end	
end

if __FILE__ == $0
	Gtk.init
	Main.new()
	Gtk.main
end
