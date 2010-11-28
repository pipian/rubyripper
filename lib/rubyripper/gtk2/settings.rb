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

# The class GtkSettings handles the rubyripper window while viewing or
# editing the settings.
# Notice that the left part of the gui with the icons is not in this class

class GtkSettings
attr_reader :display

	def initialize(settings, settingsClass)
		@settings = settings
		@settingsClass = settingsClass
		@display = Gtk::Notebook.new # Create a notebook (multiple pages)
		ripobjects_frame1()
		ripobjects_frame2()
		ripobjects_frame3()
		gapObjectsFrame1()
		gapObjectsFrame2()
		gapObjectsFrame3()
		gapObjectsFrame4()
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
#toc settings
		@create_cue.active = @settings['create_cue']
		@create_single_file.active = @settings['image']
		@ripHiddenAudio.active = @settings['ripHiddenAudio']
		@markHiddenTrackSpin.value = @settings['minLengthHiddenTrack'].to_f
		@appendPregaps.active = @settings['pregaps'] == 'append'
		@prependPregaps.active = @settings['pregaps'] == 'prepend'
		@correctPreEmphasis.active = @settings['preEmphasis'] == 'sox'
		@doNotCorrectPreEmphasis.active = @settings['preEmphasis'] == 'cue'
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
		@noSpaces.active = @settings['noSpaces']
		@noCapitals.active = @settings['noCapitals']
		@maxThreads.value = @settings['maxThreads'].to_f
		@normalize.active = if @settings['normalize'] == false ; 0 elsif @settings['normalize'] == "replaygain" ; 1 else 2 end
		@modus.active = if @settings['gain'] == "album" ; 0 else 1 end
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
#toc settings
		@settings['create_cue'] = @create_cue.active?
		@settings['image'] = @create_single_file.active?
		@settings['ripHiddenAudio'] = @ripHiddenAudio.active?
		@settings['minLengthHiddenTrack'] = @markHiddenTrackSpin.value.to_i
		@settings['pregaps'] = @appendPregaps.active? ? 'append' : 'prepend'
		@settings['preEmphasis'] = @correctPreEmphasis.active? ? 'sox' : 'cue'
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
		@settings['noSpaces'] = @noSpaces.active?
		@settings['noCapitals'] = @noCapitals.active?
		@settings['maxThreads'] = @maxThreads.value.to_i

		# The gtk2 interface gets crazy on older versions of the bindings and threads
		if Gtk::BINDING_VERSION[1] < 18 && @settings['maxThreads'] > 0
			@settings['maxThreads'] = 0
			puts "WARNING: Threads are not supported on ruby gtk2-bindings"
			puts "that are older than 0.18.0. Setting them to zero."
			puts "Please upgrade your bindings if you want threads."
		end
		
		@settings['normalize'] = if @normalize.active == 0 ; false elsif @normalize.active == 1 ; "replaygain" else "normalize" end
		@settings['gain'] = if @modus.active ==0 ; "album" else "track" end
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
		@settingsClass.save(@settings) #also update the config file
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
		@offset_button.signal_connect("clicked") {Thread.new{`#{@settings['browser']} #{@offset_button.uri}`}}
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
		@all_chunks_spin.signal_connect("value_changed") {if @err_chunks_spin.value < @all_chunks_spin.value ; @err_chunks_spin.value = @all_chunks_spin.value end ; @err_chunks_spin.set_range(@all_chunks_spin.value,100.0)} #ensure all_chunks cannot be smaller that err_chunks.
#create frame
		@frame50= Gtk::Frame.new(_('Ripping options'))
		@frame50.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame50.border_width = 5
		@frame50.add(@table50)
	end
	
	def ripobjects_frame3 #Ripping related frame
		@table60 = Gtk::Table.new(2,3,false)
		@table60.column_spacings = 5
		@table60.row_spacings = 4
		@table60.border_width = 7
#create objects
		@rip_label = Gtk::Label.new(_("Pass cdparanoia options:")) ; @rip_label.set_alignment(0.0, 0.5)
		@eject= Gtk::CheckButton.new(_('Eject cd when finished'))
		@no_log = Gtk::CheckButton.new(_('Only keep logfile if correction is needed'))
		@rip_entry= Gtk::Entry.new ; @rip_entry.width_request = 120
#pack objects
		@table60.attach(@rip_label, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table60.attach(@rip_entry, 1, 2, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 0)
		@table60.attach(@eject, 0, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table60.attach(@no_log, 0, 2, 2, 3, Gtk::FILL|Gtk::SHRINK, Gtk::SHRINK, 0, 0)
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

	def gapObjectsFrame1
		@tableToc1 = Gtk::Table.new(3,3,false)
		@tableToc1.column_spacings = 5
		@tableToc1.row_spacings = 4
		@tableToc1.border_width = 7
#create objects
		@ripHiddenAudio = Gtk::CheckButton.new(_('Rip hidden audio sectors'))
		@markHiddenTrackLabel1 = Gtk::Label.new(_('Mark as a hidden track when bigger than'))
		@markHiddenTrackLabel2 = Gtk::Label.new(_('seconds'))
		@markHiddenTrackSpin = Gtk::SpinButton.new(0, 30, 1)
		@markHiddenTrackSpin.value = 2.0
		@ripHiddenAudio.tooltip_text = _("Uncheck this if cdparanoia crashes with your ripping drive.")
		text = _("A hidden track will rip to a seperate file if used in track modus.\nIf it's smaller the sectors will be prepended to the first track.")
		@markHiddenTrackSpin.tooltip_text = text
		@markHiddenTrackLabel1.tooltip_text = text
		@markHiddenTrackLabel2.tooltip_text = text
#pack objects
		@tableToc1.attach(@ripHiddenAudio, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@tableToc1.attach(@markHiddenTrackLabel1, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@tableToc1.attach(@markHiddenTrackSpin, 1, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@tableToc1.attach(@markHiddenTrackLabel2, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
#create frame
		@ripHiddenAudio.signal_connect("clicked"){@markHiddenTrackSpin.sensitive = @ripHiddenAudio.active?}
		@frameToc1 = Gtk::Frame.new(_('Audio sectors before track 1'))
		@frameToc1.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frameToc1.border_width = 5
		@frameToc1.add(@tableToc1)
	end
	
	def gapObjectsFrame2
		@tableToc2 = Gtk::Table.new(3,2,false)
		@tableToc2.column_spacings = 5
		@tableToc2.row_spacings = 4
		@tableToc2.border_width = 7
		#create objects
		@create_cue = Gtk::CheckButton.new(_('Create cuesheet'))
		@create_single_file = Gtk::CheckButton.new(_('Rip CD to single file'))
#pack objects
		@tableToc2.attach(@create_cue, 0, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@tableToc2.attach(@create_single_file, 0, 2, 2, 3, Gtk::FILL|Gtk::SHRINK, Gtk::SHRINK, 0, 0)
#create frame
		@frameToc2 = Gtk::Frame.new(_('Advanced Toc analysis'))
		@frameToc2.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frameToc2.border_width = 5
		@vboxToc = Gtk::VBox.new()
		@vboxToc.pack_start(@tableToc2,false,false)
		@frameToc2.add(@vboxToc)
# build hbox for cdrdao
		@cdrdaoHbox = Gtk::HBox.new(false, 5)
		@cdrdao = Gtk::Label.new(_('Cdrdao installed?'))
		@cdrdaoImage = Gtk::Image.new(Gtk::Stock::CANCEL, Gtk::IconSize::BUTTON)
		@cdrdaoHbox.pack_start(@cdrdao, false, false, 5)
		@cdrdaoHbox.pack_start(@cdrdaoImage, false, false)
	end
	
	def gapObjectsFrame3
		@tableToc3 = Gtk::Table.new(3,3,false)
		@tableToc3.column_spacings = 5
		@tableToc3.row_spacings = 4
		@tableToc3.border_width = 7
#create objects
		@appendPregaps = Gtk::RadioButton.new(_('Append pregap to the previous track'))
		@prependPregaps = Gtk::RadioButton.new(@appendPregaps, _('Prepend pregaps to the track'))
#pack objects
		@tableToc3.attach(@appendPregaps, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@tableToc3.attach(@prependPregaps, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
#create frame
		@frameToc3 = Gtk::Frame.new(_('Handling pregaps other than track 1'))
		@frameToc3.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frameToc3.border_width = 5
		@frameToc3.add(@tableToc3)
		@vboxToc.pack_start(@frameToc3,false,false)
	end

	def gapObjectsFrame4
		@tableToc4 = Gtk::Table.new(3,3,false)
		@tableToc4.column_spacings = 5
		@tableToc4.row_spacings = 4
		@tableToc4.border_width = 7
#create objects
		@correctPreEmphasis = Gtk::RadioButton.new(_('Correct pre-emphasis tracks with sox'))
		@doNotCorrectPreEmphasis = Gtk::RadioButton.new(@correctPreEmphasis, _("Save the pre-emphasis tag in the cuesheet."))
#pack objects
		@tableToc4.attach(@correctPreEmphasis, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@tableToc4.attach(@doNotCorrectPreEmphasis, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
#create frame
		@frameToc4 = Gtk::Frame.new(_('Handling tracks with pre-emphasis'))
		@frameToc4.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frameToc4.border_width = 5
		@frameToc4.add(@tableToc4)
		@vboxToc.pack_start(@frameToc4,false,false)
#pack all frames into a single page
		setSignalsToc()
		@pageToc = Gtk::VBox.new #One VBox to rule them all
		[@frameToc1, @cdrdaoHbox, @frameToc2].each{|frame| @pageToc.pack_start(frame,false,false)}
		@pageTocLabel = Gtk::Label.new(_("TOC analysis"))
		@display.append_page(@pageToc, @pageTocLabel)
	end
	
	#check if cdrdao is installed
	def cdrdaoInstalled
		if installed('cdrdao')
			@cdrdaoImage.stock = Gtk::Stock::APPLY
			@frameToc2.each{|child| child.sensitive = true}
		else
			@cdrdaoImage.stock = Gtk::Stock::CANCEL
			@create_cue.active = false
			@frameToc2.each{|child| child.sensitive = false}
		end
	end
	
	# signal for createCue
	def createCue
		@create_single_file.sensitive = @create_cue.active?
		@create_single_file.active = false if !@create_cue.active?
		@tableToc3.each{|child| child.sensitive = @create_cue.active?}
		@tableToc4.each{|child| child.sensitive = @create_cue.active?}
	end
	
	# signal for create single file
	def createSingle
		@tableToc3.each{|child| child.sensitive = !@create_single_file.active?}
		@correctPreEmphasis.active = true
		@doNotCorrectPreEmphasis.sensitive = !@create_single_file.active?
	end
	
	#set signals for the toc
	def setSignalsToc
		cdrdaoInstalled()
		createSingle()
		createCue()
		@create_cue.signal_connect("clicked"){createCue()}
		@create_cue.signal_connect("clicked"){`killall cdrdao 2>1` if !@create_cue.active?}
		@create_single_file.signal_connect("clicked"){createSingle()}
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
		@table80 = Gtk::Table.new(4,2,false)
		@table80.column_spacings = 5
		@table80.row_spacings = 4
		@table80.border_width = 7
#creating objects
		@playlist = Gtk::CheckButton.new(_("Create m3u playlist"))
		@noSpaces = Gtk::CheckButton.new(_("Replace spaces with underscores in filenames"))
		@noCapitals = Gtk::CheckButton.new(_("Downsize all capital letters in filenames"))
		@maxThreads = Gtk::SpinButton.new(0.0, 10.0, 1.0)
		@maxThreadsLabel = Gtk::Label.new(_("Number of extra encoding threads"))
#packing objects
		@table80.attach(@maxThreadsLabel, 0, 1, 0, 1, Gtk::FILL, Gtk::FILL, 0, 0)
		@table80.attach(@maxThreads, 1, 2, 0, 1, Gtk::FILL, Gtk::FILL, 0, 0)
		@table80.attach(@playlist, 0, 2, 1, 2, Gtk::FILL, Gtk::FILL, 0, 0)
		@table80.attach(@noSpaces, 0, 2, 2, 3, Gtk::FILL, Gtk::FILL, 0, 0)
		@table80.attach(@noCapitals, 0, 2, 3, 4, Gtk::FILL, Gtk::FILL, 0, 0)
		
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
		@normalize.signal_connect("changed") {if @normalize.active == 0 ; @modus.sensitive = false else @modus.sensitive = true end}
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
		@basedir_entry.signal_connect("key_release_event"){@example_label.text = getExampleFilenameNormal(@basedir_entry.text, @naming_normal_entry.text) ; false}
		@basedir_entry.signal_connect("button_release_event"){@example_label.text = getExampleFilenameNormal(@basedir_entry.text, @naming_normal_entry.text) ; false}
		@naming_normal_entry.signal_connect("key_release_event"){@example_label.text = getExampleFilenameNormal(@basedir_entry.text, @naming_normal_entry.text) ; false}
		@naming_normal_entry.signal_connect("button_release_event"){@example_label.text = getExampleFilenameNormal(@basedir_entry.text, @naming_normal_entry.text) ; false}
		@naming_normal_entry.signal_connect("focus-out-event"){if not File.dirname(@naming_normal_entry.text) =~ /%a|%b/ ; @naming_normal_entry.text = "%a (%y) %b/" + @naming_normal_entry.text; preventStupidness() end; false}
		@naming_various_entry.signal_connect("key_release_event"){@example_label.text = getExampleFilenameVarious(@basedir_entry.text, @naming_various_entry.text) ; false}
		@naming_various_entry.signal_connect("button_release_event"){@example_label.text = getExampleFilenameVarious(@basedir_entry.text, @naming_various_entry.text) ; false}
		@naming_various_entry.signal_connect("focus-out-event"){if not File.dirname(@naming_various_entry.text) =~ /%a|%b/ ; @naming_various_entry.text = "%a (%y) %b/" + @naming_various_entry.text; preventStupidness() end; false}
		@naming_image_entry.signal_connect("key_release_event"){@example_label.text = getExampleFilenameVarious(@basedir_entry.text, @naming_image_entry.text) ; false}
		@naming_image_entry.signal_connect("button_release_event"){@example_label.text = getExampleFilenameVarious(@basedir_entry.text, @naming_image_entry.text) ; false}
		@naming_image_entry.signal_connect("focus-out-event"){if not File.dirname(@naming_image_entry.text) =~ /%a|%b/ ; @naming_image_entry.text = "%a (%y) %b/" + @naming_image_entry.text; preventStupidness() end; false}
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

	# Would you believe this actually prevents bug reports?
	def preventStupidness()
		puts "You need to make a subdirectory with at least the artist or album"
		puts "name in it. Otherwise your directory will be overwritten each time!"
		puts "To protect you from making these unwise choices this is corrected :P"
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
		@display.signal_connect("switch_page") do |a, b, page|
			if page == 1
				cdrdaoInstalled()
			elsif page == 4
				@example_label.text = getExampleFilenameNormal(@basedir_entry.text, @naming_normal_entry.text)
			end
		end
		@display.append_page(@page4, @page4_label)
	end
end

