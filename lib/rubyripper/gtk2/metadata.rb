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

# The GtkMetadata class shows the metadata info of the disc and tracks.
# Notice that the left part of the gui with the icons is not in this class

class GtkMetadata
attr_reader :display, :tracks_to_rip

	def initialize(cdinfo)
		@cd = cdinfo
		@tracks_to_rip = Array.new
		discinfo_objects() #create all necessary objects for displaying the discinfo
		trackselection_objects() #create all necessary objects for displaying the trackselection
		updateMetadata()
		pack_both() #pack them together so we can show this beauty to the world :)
	end

	def refreshDisc(cdinfo)
		@cd = cdinfo
		@tracks_to_rip = Array.new
		updateDisc()
		updateTracks()
	end

	def discinfo_objects
		setDiscValues()
		configDiscValues()
		setDiscSignals()
		packDiscObjects()
	end

	def trackselection_objects
		setTrackValues()
		configTrackValues()
		setTrackSignals()
		packTrackObjects()
	end
	
	def pack_both
		setDisplayValues()
		configDisplayValues()
		packDisplayObjects()
	end

	def setDiscValues()
		@table10 = Gtk::Table.new(4,4,false)

		@artistLabel = Gtk::Label.new(_('Artist:'))
		@albumLabel = Gtk::Label.new(_('Album:'))
		@genreLabel = Gtk::Label.new(_('Genre:'))
		@yearLabel = Gtk::Label.new(_('Year:'))
		@varCheckbox = Gtk::CheckButton.new(_('Mark disc as various artist'))

		@freezeCheckbox = Gtk::CheckButton.new(_('Freeze disc info'))
		@discNumberLabel = Gtk::Label.new(_('Disc:'))
		@discNumberSpin = Gtk::SpinButton.new(1.0, 99.0, 1.0)

		@artistEntry = Gtk::Entry.new()
		@albumEntry = Gtk::Entry.new()
		@genreEntry = Gtk::Entry.new()
		@yearEntry = Gtk::Entry.new()
	end

	def configDiscValues()
		@table10.column_spacings = 5
		@table10.row_spacings = 4
		@table10.border_width = 7

		@artistLabel.set_alignment(0.0, 0.5)
		@albumLabel.set_alignment(0.0, 0.5)
		@genreLabel.set_alignment(0.0, 0.5)
		@yearLabel.set_alignment(0.0, 0.5)

		@genreEntry.width_request = 100
		@yearEntry.width_request = 100
		
		@freezeCheckbox.tooltip_text = _("Use this option to keep the disc info\nfor albums that span multiple discs")
		@discNumberLabel.set_alignment(0.0, 0.5)
		@discNumberLabel.sensitive = false
		@discNumberSpin.value = 1.0
		@discNumberSpin.sensitive = false
	end

	def setDiscSignals()
		@varCheckbox.signal_connect("toggled") do
			@varCheckbox.active? ? setVarArtist() : unsetVarArtist()
		end

		@freezeCheckbox.signal_connect("toggled") do
			@discNumberLabel.sensitive = @freezeCheckbox.active?
			@discNumberSpin.sensitive = @freezeCheckbox.active?
		end
	end

	def packDiscObjects()
		@table10.attach(@artistLabel, 0,1,0,1, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column
		@table10.attach(@albumLabel,0,1,1,2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table10.attach(@artistEntry, 1,2,0,1, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0,0) #2nd column
		@table10.attach(@albumEntry, 1, 2, 1, 2, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0)
		@table10.attach(@genreLabel, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #3rd column
		@table10.attach(@yearLabel, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table10.attach(@genreEntry, 3, 4, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 0) #4th column
		@table10.attach(@yearEntry, 3 , 4, 1, 2, Gtk::SHRINK, Gtk::SHRINK, 0, 0)
		@table10.attach(@varCheckbox, 0, 4, 3, 4, Gtk::FILL, Gtk::SHRINK, 0, 0)
		@table10.attach(@freezeCheckbox, 0, 2, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)		
		@table10.attach(@discNumberLabel, 2, 3, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)		
		@table10.attach(@discNumberSpin, 3, 4, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
	end

	def setTrackValues(update = false)
		@table20 = Gtk::Table.new(@cd.audiotracks + 1, 4, false) if !update

		@allTracksButton = Gtk::CheckButton.new(_('All'))
		@varArtistLabel = Gtk::Label.new(_('Artist'))
		@tracknameLabel = Gtk::Label.new(_("Tracknames \(%s tracks\)") % [@cd.audiotracks])
		@lengthLabel = Gtk::Label.new(_("Length \(%s\)") % [@cd.playtime])
		
		@checkTrackArray = Array.new ; @varArtistEntryArray = Array.new ; @trackEntryArray = Array.new ; @lengthLabelArray = Array.new
		@cd.audiotracks.times do |track|
			@checkTrackArray << Gtk::CheckButton.new((track + 1).to_s)
			@varArtistEntryArray << Gtk::Entry.new()
			@trackEntryArray << Gtk::Entry.new()
			@lengthLabelArray << Gtk::Label.new(@cd.getLengthText(track + 1))
		end
	end

	def configTrackValues(update = false)
		if !update
			@table20.column_spacings = 5
			@table20.row_spacings = 4
			@table20.border_width = 7
		end

		@allTracksButton.active = true
		@checkTrackArray.each{|checkbox| checkbox.active = true}
	end

	def setTrackSignals()
		@allTracksButton.signal_connect("toggled") do
			@allTracksButton.active? ? @checkTrackArray.each{|box| box.active = true} : @checkTrackArray.each{|box| box.active = false} #signal to toggle on/off all tracks 
		end
	end

	# pack with or without support for various artists
	def packTrackObjects(varArtist = false)
		@table20.attach(@allTracksButton, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 1st row
		@table20.attach(@lengthLabel, 3, 4, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #4th column, 1st row

		if varArtist == true
			@table20.attach(@varArtistLabel, 1, 2, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column, 1st row
			@table20.attach(@tracknameLabel, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #3rd column, 1st row
		else
			@table20.attach(@tracknameLabel, 1, 3, 0, 1, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0)
		end
		
		@cd.audiotracks.times do |index|
			@table20.attach(@checkTrackArray[index], 0, 1, 1 + index, 2 + index, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 2nd row till end
			@table20.attach(@lengthLabelArray[index],3, 4, 1 + index, 2 + index, Gtk::FILL, Gtk::SHRINK, 0, 0) #4th column, 2nd row till end
			
			if varArtist == true
				@table20.attach(@varArtistEntryArray[index], 1, 2, index + 1, index + 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
				@table20.attach(@trackEntryArray[index], 2, 3, index + 1, index + 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
			else
				@table20.attach(@trackEntryArray[index],1, 3, 1 + index, 2 + index, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) #2nd + 3rd column, 2nd row till end
			end
			
		end
	end

	def setDisplayValues()
		@label10 = Gtk::Label.new()
		@frame10 = Gtk::Frame.new()

		@scrolledWindow = Gtk::ScrolledWindow.new()

		@label20 = Gtk::Label.new()
		@frame20 = Gtk::Frame.new()

		@display = Gtk::VBox.new #One VBox to rule them all
	end

	def configDisplayValues()
		@label10.set_markup(_("<b>Disc info</b>"))
		@frame10.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame10.label_widget = @label10
		@frame10.border_width = 5
		
		@scrolledWindow.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		@scrolledWindow.set_border_width(5)

		@label20.set_markup(_("<b>Track selection</b>"))
		@frame20.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
		@frame20.label_widget = @label20
		@frame20.border_width = 5
	end

	def packDisplayObjects()
		@frame10.add(@table10)
		
		@scrolledWindow.add_with_viewport(@table20)
		@frame20.add(@scrolledWindow)

		@display.pack_start(@frame10, false, false)
		@display.pack_start(@frame20, true, true)
	end

	def updateDisc()
		if @freezeCheckbox.active? == false
			@artistEntry.text = @cd.md.artist
			@albumEntry.text = @cd.md.album
			@genreEntry.text = @cd.md.genre
			@yearEntry.text = @cd.md.year
		else
			@discNumberSpin.value += 1.0
		end
		if @cd.md.varArtists.empty?
			@varCheckbox.active = false
		end
	end

	def updateTracks()
		@table20.each{|child| @table20.remove(child)} #clear current objects
		@table20.resize(@cd.audiotracks + 1, 4) #resize to new disc
		setTrackValues(update = true) #rebuild the new track objects
		configTrackValues(update = true) # configure the new ones
		setTrackSignals() # reset the signals
		packTrackObjects() # pack the objects into the table
		@table20.show_all()
	end
	
	def updateMetadata
		if @freezeCheckbox.active? == false
			if not @cd.md.varArtists.empty? ; @varCheckbox.active = true end
			@artistEntry.text = @cd.md.artist ; @albumEntry.text = @cd.md.album
			@yearEntry.text = @cd.md.year ; @genreEntry.text = @cd.md.genre
		end
		@cd.audiotracks.times{|index| @trackEntryArray[index].text = @cd.md.tracklist[index]}
		unless @cd.md.varArtists.empty? ; setVarArtist() end
	end

	def setVarArtist()
		# restore the old info when available
		@cd.md.redoVarArtist()
		# make sure each track has an artist name
		@cd.audiotracks.times{|time| if @cd.md.varArtists[time] == nil;  @cd.md.varArtists[time] = _('Unknown') end}
		# now fill the array
		@cd.audiotracks.times{|index| @varArtistEntryArray[index].text = @cd.md.varArtists[index]}
		#reset the tracknames (no artist will be included)
		@cd.audiotracks.times{|index| @trackEntryArray[index].text = @cd.md.tracklist[index]}
		# remove all current objects from array, as we're repacking them
		@table20.each{|child| @table20.remove(child)}
		# repack into table20
		packTrackObjects(varArtist = true)
		# show all updates
		@table20.show_all()
	end

	def unsetVarArtist()
		# giving the backend the signal to revert last actions
		@cd.md.undoVarArtist() if !@cd.md.varArtists.empty?
		# reset the Trackname fields (give full trackname, including detected artists)
		@cd.audiotracks.times{|index| @trackEntryArray[index].text = @cd.md.tracklist[index]}
		# remove all current objects from array, as we're repacking them
		@table20.each{|child| @table20.remove(child)}
		# repack into table20
		packTrackObjects(varArtist = false)
		#show all updates
		@table20.show_all()
	end
	
	def save_updates(image=false) # save all updated info from the user
		@cd.md.artist = @artistEntry.text
		@cd.md.album = @albumEntry.text
		@cd.md.genre = @genreEntry.text
		@cd.md.year = @yearEntry.text if @yearEntry.text.to_i != 0
		@cd.md.discNumber = @discNumberSpin.value.to_i if @freezeCheckbox.active?
		
		@tracks_to_rip = Array.new #reset the array
		
		if image
		    @tracks_to_rip = ["image"]
		else
		    @cd.audiotracks.times do |index|
			@cd.md.tracklist[index] = @trackEntryArray[index].text
			if @checkTrackArray[index].active? ; @tracks_to_rip << index + 1 end
		    end
		end
		
		unless @cd.md.varArtists.empty?
			@cd.audiotracks.times{|index| @cd.md.varArtists[index] = @varArtistEntryArray[index].text}
		end
	end
end
