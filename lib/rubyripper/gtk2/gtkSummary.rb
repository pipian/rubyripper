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

require 'rubyripper/preferences/main'
require 'rubyripper/system/execute'

# Summary handles the rubyripper window while displaying the summary of a rip.
# Notice that the left part of the gui with the icons is not in this class
class GtkSummary
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :display

  def initialize(directory, summary, succes)
    @prefs = Preferences::Main.instance
    @exec = Execute.new
    showMainResult(succes)
    buildSummary(summary)
    buildOpenLogButton()
    buildOpenDirButton()
    setSignals(directory)
    assemblePage()
  end

  def showMainResult(succes)
    if succes == true
      @label1 = Gtk::Label.new(_("The rip has succesfully finished.\nA short summary is shown below."))
      @image1 = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
    else
      @label1 = Gtk::Label.new(_("The rip had some problems.\nA short summary is shown below."))
      @image1 = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
    end
  end

  def buildSummary(summary)
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
  end

  def buildOpenLogButton
    @button1 = Gtk::Button.new()
    @label2 = Gtk::Label.new(_("Open log file"))
    @image2 = Gtk::Image.new(Gtk::Stock::EXECUTE, Gtk::IconSize::LARGE_TOOLBAR)
    @hbox2 = Gtk::HBox.new()
    [@image2, @label2].each{|object| @hbox2.pack_start(object)}
    @button1.add(@hbox2)
  end

  def buildOpenDirButton
    # assemble button 2
    @button2 = Gtk::Button.new()
    @label3 = Gtk::Label.new(_("Open directory"))
    @image3 = Gtk::Image.new(Gtk::Stock::OPEN, Gtk::IconSize::LARGE_TOOLBAR)
    @hbox3 = Gtk::HBox.new()
    [@image3, @label3].each{|object| @hbox3.pack_start(object)}
    @button2.add(@hbox3)
  end

  def setSignals(directory)
    @button1.signal_connect("released") do
      Thread.new{@exec.launch("#{@prefs.editor} #{directory}/ripping.log")}
    end

    @button2.signal_connect("released") do
      Thread.new{@exec.launch("#{@prefs.filemanager} #{directory}")}
    end
  end

  def assemblePage
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
