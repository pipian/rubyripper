#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: 
#    you can redistribute it and/or modify it under the terms of
#    the GNU General Public License as published by
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

require 'rubyripper/disc/disc'

# The GtkDisc class shows the disc info
# This is placed in the frame of the main window
# Beside the vertical buttonbox
class GtkDisc
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :display, :error, :selection, :disc
 
  def initalize
    @discInfoTable = nil
    @trackInfoTable = nil
    @display = nil
  end
  
  def start
    refresh(firsttime = true)   
  end

  def refresh(firsttime=false)
    @selection = []
    @error = nil
    @disc = Disc.new()
    @disc.scan()

    if @disc.status == 'ok'
      @md = @disc.metadata
      buildDiscInfo unless @discInfoTable
      buildTrackInfo()
      buildLayout() unless @display
      updateDisc(firsttime)
      updateTracks()
    else
      @error = @disc.error
    end
  end
  
  # store any updates the user has made and save the selected tracks
  def save
    @md.artist = @artistEntry.text
    @md.album = @albumEntry.text
    @md.genre = @genreEntry.text
    @md.year = @yearEntry.text if @yearEntry.text.to_i != 0
    @md.discNumber = @discNumberSpin.value.to_i if @freezeCheckbox.active?

    @selection = Array.new #reset the array
    (1..@disc.audiotracks).each do |track|
      @md.setTrackname(track, @trackEntryArray[track-1].text)
      @md.setVarArtist(track, @varArtistEntryArray[track-1].text) if @md.various?
      @selection << track if @checkTrackArray[track-1].active?
    end
  end
  
  private
  
  #create all necessary objects for displaying the discinfo
  def buildDiscInfo
    setDiscValues()
    configDiscValues()
    setDiscSignals()
    packDiscObjects()
  end

  #create all necessary objects for displaying the trackselection
  def buildTrackInfo
    setTrackInfoTable()
    setTrackValues()
    configTrackValues()
    setTrackSignals()
    packTrackObjects()
  end
  
  #pack them together so we can show this beauty to the world :)
  def buildLayout
    setDisplayValues()
    configDisplayValues()
    packDisplayObjects()
  end

  def setDiscValues()
    @discInfoTable = Gtk::Table.new(4,4,false)

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
    @discInfoTable.column_spacings = 5
    @discInfoTable.row_spacings = 4
    @discInfoTable.border_width = 7

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
    @discInfoTable.attach(@artistLabel, 0,1,0,1, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column
    @discInfoTable.attach(@albumLabel,0,1,1,2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @discInfoTable.attach(@artistEntry, 1,2,0,1, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0,0) #2nd column
    @discInfoTable.attach(@albumEntry, 1, 2, 1, 2, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0)
    @discInfoTable.attach(@genreLabel, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #3rd column
    @discInfoTable.attach(@yearLabel, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @discInfoTable.attach(@genreEntry, 3, 4, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 0) #4th column
    @discInfoTable.attach(@yearEntry, 3 , 4, 1, 2, Gtk::SHRINK, Gtk::SHRINK, 0, 0)
    @discInfoTable.attach(@varCheckbox, 0, 4, 3, 4, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @discInfoTable.attach(@freezeCheckbox, 0, 2, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @discInfoTable.attach(@discNumberLabel, 2, 3, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @discInfoTable.attach(@discNumberSpin, 3, 4, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
  end

  def setTrackInfoTable()
    if not @trackInfoTable
      @trackInfoTable = Gtk::Table.new(@disc.audiotracks + 1, 4, false)
    else
      @trackInfoTable.each{|child| @trackInfoTable.remove(child)}
      @trackInfoTable.resize(@disc.audiotracks + 1, 4)
    end
  end
  
  def setTrackValues
    @allTracksButton = Gtk::CheckButton.new(_('All'))
    @varArtistLabel = Gtk::Label.new(_('Artist'))
    @tracknameLabel = Gtk::Label.new(_("Track names \(%s track(s)\)") % [@disc.audiotracks])
    @lengthLabel = Gtk::Label.new(_("Length \(%s\)") % [@disc.playtime])

    @checkTrackArray = Array.new ; @varArtistEntryArray = Array.new ; @trackEntryArray = Array.new ; @lengthLabelArray = Array.new
    (1..@disc.audiotracks).each do |track|
      @checkTrackArray << Gtk::CheckButton.new(track.to_s)
      @varArtistEntryArray << Gtk::Entry.new()
      @trackEntryArray << Gtk::Entry.new()
      @lengthLabelArray << Gtk::Label.new(@disc.getLengthText(track))
    end
  end

  def configTrackValues
    @trackInfoTable.column_spacings = 5
    @trackInfoTable.row_spacings = 4
    @trackInfoTable.border_width = 7

    @allTracksButton.active = true
    @checkTrackArray.each{|checkbox| checkbox.active = true}
  end

  def setTrackSignals()
    @allTracksButton.signal_connect("toggled") do
      @allTracksButton.active? ? @checkTrackArray.each{|box| box.active = true} : @checkTrackArray.each{|box| box.active = false} #signal to toggle on/off all tracks
    end
  end

  # pack with or without support for various artists
  def packTrackObjects
    @trackInfoTable.attach(@allTracksButton, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 1st row
    @trackInfoTable.attach(@lengthLabel, 3, 4, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #4th column, 1st row

    if @md.various?
      @trackInfoTable.attach(@varArtistLabel, 1, 2, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column, 1st row
      @trackInfoTable.attach(@tracknameLabel, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #3rd column, 1st row
    else
      @trackInfoTable.attach(@tracknameLabel, 1, 3, 0, 1, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0)
    end

    @disc.audiotracks.times do |index|
      @trackInfoTable.attach(@checkTrackArray[index], 0, 1, 1 + index, 2 + index, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 2nd row till end
      @trackInfoTable.attach(@lengthLabelArray[index],3, 4, 1 + index, 2 + index, Gtk::FILL, Gtk::SHRINK, 0, 0) #4th column, 2nd row till end

      if @md.various?
        @trackInfoTable.attach(@varArtistEntryArray[index], 1, 2, index + 1, index + 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
        @trackInfoTable.attach(@trackEntryArray[index], 2, 3, index + 1, index + 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
      else
        @trackInfoTable.attach(@trackEntryArray[index],1, 3, 1 + index, 2 + index, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) #2nd + 3rd column, 2nd row till end
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
    @frame10.add(@discInfoTable)

    @scrolledWindow.add_with_viewport(@trackInfoTable)
    @frame20.add(@scrolledWindow)

    @display.pack_start(@frame10, false, false)
    @display.pack_start(@frame20, true, true)
  end

  def updateDisc(firsttime=false)
    if @freezeCheckbox.active? == false
      @artistEntry.text = @md.artist
      @albumEntry.text = @md.album
      @genreEntry.text = @md.genre
      @yearEntry.text = @md.year
    else
      @discNumberSpin.value += 1.0 unless firsttime
    end
    
    @varCheckbox.active = true if @md.various?
  end

  def updateTracks
    (1..@disc.audiotracks).each do |track|
      @trackEntryArray[track - 1].text = @md.trackname(track)
    end
    setVarArtist() if @md.various?
    @trackInfoTable.show_all()
  end
  
  # update the view for various artists
  def setVarArtist()
    return true if @md.various?
    @md.markVarArtist()
    @disc.audiotracks.times{|index| @varArtistEntryArray[index].text = @md.getVarArtist(index + 1)}
    @disc.audiotracks.times{|index| @trackEntryArray[index].text = @md.trackname(index + 1)}
    updateTracksView()
  end

  # update the view for normal artists
  def unsetVarArtist()
    return true unless @md.various?
    @md.unmarkVarArtist()
    @disc.audiotracks.times{|index| @trackEntryArray[index].text = @md.trackname(index + 1)}
    updateTracksView()
  end
  
  # remove current objects and repackage the view
  def updateTracksView
    @trackInfoTable.each{|child| @trackInfoTable.remove(child)}
    packTrackObjects()
    @trackInfoTable.show_all()
  end
end
