#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
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

# The class GtkPreferences allows the user to change his preferences
# This class is responsible for building the frame on the right side

class GtkPreferences
attr_reader :display

  DEFAULT_COLUMN_SPACINGS = 5
  DEFAULT_ROW_SPACINGS = 4
  DEFAULT_BORDER_WIDTH = 7

  def initialize(prefs=nil, deps=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @deps = deps ? deps : Dependency.instance
  end
  
  def start
    @display = Gtk::Notebook.new # Create a notebook (multiple pages)
    buildSecureRippingTab()
    buildTocAnalysisTab()
    buildCodecsTab()
    buildMetadataTab()
    buildOtherTab()
    loadPreferences()
  end
  
  # save current preferences
  def save
    savePreferences
  end
  
  private
  
  # build first tab
  def buildSecureRippingTab
    buildFrameCdromDevice()
    buildFrameRippingOptions()
    buildFrameRippingRelated()
  end
  
  # build second tab
  def buildTocAnalysisTab
    buildFrameAudioSectorsBeforeTrackOne()
    buildFrameAdvancedTocAnalysis()
    buildFrameHandlingPregapsOtherThanTrackOne()
    buildFrameHandlingTracksWithPreEmphasis()
  end
  
  # build third tab
  def buildCodecsTab
    buildFrameSelectAudioCodecs()
    buildFrameCodecRelated()
    buildFrameNormalizeToStandardVolume()
  end
  
  # build fourth tab
  def buildMetadataTab
    freedbobjects_frame()
  end
  
  # build fifth tab
  def buildOtherTab
    buildFrameFilenamingScheme()
    buildFrameProgramsOfChoice()
    buildFrameDebugOptions()
    pack_other_frames()
  end

  # Fill all objects with the right value
  def loadPreferences
#ripping settings
    @cdromEntry.text = @prefs.cdrom
    @cdromOffsetSpin.value = @prefs.offset.to_f
    @padMissingSamples.active = @prefs.padMissingSamples
    @allChunksSpin.value = @prefs.reqMatchesAll.to_f
    @errChunksSpin.value = @prefs.reqMatchesErrors.to_f
    @maxSpin.value = @prefs.maxTries.to_f
    @ripEntry.text = @prefs.rippersettings
    @eject.active = @prefs.eject
    @noLog.active = @prefs.noLog
#toc settings
    @createCue.active = @prefs.createCue
    @image.active = @prefs.image
    @ripHiddenAudio.active = @prefs.ripHiddenAudio
    @minLengthHiddenTrackSpin.value = @prefs.minLengthHiddenTrack.to_f
    @appendPregaps.active = @prefs.preGaps == 'append'
    @prependPregaps.active = @prefs.preGaps == 'prepend'
    @correctPreEmphasis.active = @prefs.preEmphasis == 'sox'
    @doNotCorrectPreEmphasis.active = @prefs.preEmphasis == 'cue'
#codec settings
    @flac.active = @prefs.flac
    @vorbis.active = @prefs.vorbis
    @mp3.active = @prefs.mp3
    @wav.active = @prefs.wav
    @other.active = @prefs.other
    @flacEntry.text = @prefs.settingsFlac
    @vorbisEntry.text = @prefs.settingsVorbis
    @mp3Entry.text = @prefs.settingsMp3
    @otherEntry.text = @prefs.settingsOther
    @playlist.active = @prefs.playlist
    @noSpaces.active = @prefs.noSpaces
    @noCapitals.active = @prefs.noCapitals
    @maxThreads.value = @prefs.maxThreads.to_f
    @normalize.active = loadNormalizer()
    @modus.active = @prefs.gain == 'album' ? 0 : 1
#freedb
    @enableFreedb.active = @prefs.metadataProvider == 'freedb'
    @firstHit.active = @prefs.firstHit
    @freedbServerEntry.text = @prefs.site
    @freedbUsernameEntry.text = @prefs.username
    @freedbHostnameEntry.text = @prefs.hostname
#other
    @basedirEntry.text = @prefs.basedir
    @namingNormalEntry.text = @prefs.namingNormal
    @namingVariousEntry.text = @prefs.namingVarious
    @namingImageEntry.text = @prefs.namingImage
    @verbose.active = @prefs.verbose
    @debug.active = @prefs.debug
    @editorEntry.text = @prefs.editor
    @filemanagerEntry.text = @prefs.filemanager
  end
  
  def loadNormalizer
    case @prefs.normalizer
      when _('none') then 0
      when _('replaygain') then 1
      when _('normalize') then 2
    end
  end

  # update the preferences object with latest values
  def savePreferences
#ripping settings
    @prefs.cdrom = @cdromEntry.text
    @prefs.offset = @cdromOffsetSpin.value.to_i
    @prefs.padMissingSamples = @padMissingSamples.active?
    @prefs.reqMatchesAll = @allChunksSpin.value.to_i
    @prefs.reqMatchesErrors = @errChunksSpin.value.to_i
    @prefs.maxTries = @maxSpin.value.to_i
    @prefs.rippersettings = @ripEntry.text
    @prefs.eject = @eject.active?
    @prefs.noLog = @noLog.active?
#toc settings
    @prefs.createCue = @createCue.active?
    @prefs.image = @image.active?
    @prefs.ripHiddenAudio = @ripHiddenAudio.active?
    @prefs.minLengthHiddenTrack = @minLengthHiddenTrackSpin.value.to_i
    @prefs.preGaps = @appendPregaps.active? ? 'append' : 'prepend'
    @prefs.preEmphasis = @correctPreEmphasis.active? ? 'sox' : 'cue'
#codec settings
    @prefs.flac = @flac.active?
    @prefs.vorbis = @vorbis.active?
    @prefs.mp3 = @mp3.active?
    @prefs.wav = @wav.active?
    @prefs.other = @other.active?
    @prefs.settingsFlac = @flacEntry.text
    @prefs.settingsVorbis = @vorbisEntry.text
    @prefs.settingsMp3 = @mp3Entry.text
    @prefs.settingsOther = @otherEntry.text
    @prefs.playlist = @playlist.active?
    @prefs.noSpaces = @noSpaces.active?
    @prefs.noCapitals = @noCapitals.active?
    @prefs.maxThreads = @maxThreads.value.to_i
    preventThreadProblemsOnOlderBindings()
    @prefs.normalizer = saveNormalizer()
    @prefs.gain = @modus.active == 0 ? "album" : "track"
#freedb
    @prefs.metadataProvider = @enableFreedb.active? ? 'freedb' : 'none' 
    @prefs.firstHit = @firstHit.active?
    @prefs.site = @freedbServerEntry.text
    @prefs.username = @freedbUsernameEntry.text
    @prefs.hostname = @freedbHostnameEntry.text
#other
    @prefs.basedir = @basedirEntry.text
    @prefs.namingNormal = @namingNormalEntry.text
    @prefs.namingVarious = @namingVariousEntry.text
    @prefs.namingImage = @namingImageEntry.text
    @prefs.verbose = @verbose.active?
    @prefs.debug = @debug.active?
    @prefs.editor = @editorEntry.text
    @prefs.filemanager = @filemanagerEntry.text
    @prefs.save() #also update the config file
  end
  
  def saveNormalizer
    case @normalize.active
      when 0 then 'none'
      when 1 then 'replaygain'
      when 2 then 'normalize'
    end
  end

  # The interface can't handle threads nicely on old versions        
  def preventThreadProblemsOnOlderBindings
    if Gtk::BINDING_VERSION[0] < 1 && 
        Gtk::BINDING_VERSION[1] < 18 && @prefs.maxThreads > 0
      @prefs.maxThreads = 0
      puts "WARNING: Threads are not supported on ruby gtk2-bindings"
      puts "that are older than 0.18.0. Setting them to zero."
      puts "Please upgrade your bindings if you want threads."
    end
  end
  
  # helpfunction to create a table
  def newTable(rows, columns, homogeneous=false)
    table = Gtk::Table.new(rows, columns, homogeneous)
    table.column_spacings = DEFAULT_COLUMN_SPACINGS
    table.row_spacings = DEFAULT_ROW_SPACINGS
    table.border_width = DEFAULT_BORDER_WIDTH
    table
  end
  
  # helpfunction to create a frame
  def newFrame(label, child)
    frame = Gtk::Frame.new(label)
    frame.set_shadow_type(Gtk::SHADOW_ETCHED_IN)
    frame.border_width = DEFAULT_BORDER_WIDTH # was 5
    frame.add(child)
    frame
  end

  # 1st frame on secure ripping tab
  def buildFrameCdromDevice
    @table40 = newTable(rows=3, columns=3)
#creating objects
    @cdrom_label = Gtk::Label.new(_("Cdrom device:"))
    @cdrom_label.set_alignment(0.0, 0.5) # Align to the left
    @cdrom_offset_label = Gtk::Label.new(_("Cdrom offset:"))
    @cdrom_offset_label.set_alignment(0.0, 0.5)
    @cdromEntry = Gtk::Entry.new ; @cdromEntry.width_request = 120
    @cdromOffsetSpin = Gtk::SpinButton.new(-1500.0, 1500.0, 1.0)
    @cdromOffsetSpin.value = 0.0
    @offset_button = Gtk::LinkButton.new(_('List with offsets'))
    @offset_button.uri = "http://www.accuraterip.com/driveoffsets.htm"
    @offset_button.tooltip_text = _("A website which lists the offset for most drives.\nYour drivename can be found in each logfile.")
#pack objects
    @padMissingSamples = Gtk::CheckButton.new(_('Pad missing samples with zero\'s'))
    @padMissingSamples.tooltip_text = _("Cdparanoia can\'t handle offsets \
larger than 580 for \nfirst (negative offset) and last (positive offset) \
track.\nThis option fills the rest with empty samples.\n\
If disabled, the file will not have the correct size.\n\
It is recommended to enable this option.")
    @padMissingSamples.sensitive = false
    @table40.attach(@cdrom_label, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table40.attach(@cdrom_offset_label, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table40.attach(@cdromEntry, 1, 2, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 0)
    @table40.attach(@cdromOffsetSpin, 1, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table40.attach(@offset_button, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
#connect signal
    @table40.attach(@padMissingSamples, 0, 2, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @offset_button.signal_connect("clicked") {Thread.new{`#{@prefs.browser} #{@offset_button.uri}`}}
    @cdromOffsetSpin.signal_connect("value-changed"){enablePaddingOption?}
    @frame40 = newFrame(_('Cdrom device'), child=@table40)
  end
  
  # enable the padding option if the offset is >580 || <-580
  def enablePaddingOption?
    value = @cdromOffsetSpin.value.to_i
    if value > 580 || value <-580
      @padMissingSamples.sensitive = true
    else
      @padMissingSamples.sensitive = false
    end
  end

  # 2nd frame on secure ripping tab
  def buildFrameRippingOptions
    @table50 = newTable(rows=3, columns=3)
#create objects
    @all_chunks = Gtk::Label.new(_("Match all chunks:")) ; @all_chunks.set_alignment(0.0, 0.5)
    @err_chunks = Gtk::Label.new(_("Match erroneous chunks:")) ; @err_chunks.set_alignment(0.0, 0.5)
    @max_label = Gtk::Label.new(_("Maximum trials (0 = unlimited):")) ; @max_label.set_alignment(0.0, 0.5)
    @allChunksSpin = Gtk::SpinButton.new(2.0,  100.0, 1.0)
    @errChunksSpin = Gtk::SpinButton.new(2.0, 100.0, 1.0)
    @maxSpin = Gtk::SpinButton.new(0.0, 100.0, 1.0)
    @time1 = Gtk::Label.new(_("times"))
    @time2 = Gtk::Label.new(_("times"))
    @time3 = Gtk::Label.new(_("times"))
#pack objects
    @table50.attach(@all_chunks, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column
    @table50.attach(@err_chunks, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table50.attach(@max_label, 0, 1, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table50.attach(@allChunksSpin, 1, 2, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column
    @table50.attach(@errChunksSpin, 1, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table50.attach(@maxSpin, 1, 2, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table50.attach(@time1, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #3rd column
    @table50.attach(@time2, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table50.attach(@time3, 2, 3, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0)
#connect a signal to @all_chunks to make sure @err_chunks get always at least the same amount of rips as @all_chunks
    @allChunksSpin.signal_connect("value_changed") {if @errChunksSpin.value < @allChunksSpin.value ; @errChunksSpin.value = @allChunksSpin.value end ; @errChunksSpin.set_range(@allChunksSpin.value,100.0)} #ensure all_chunks cannot be smaller that err_chunks.
    @frame50= newFrame(_('Ripping options'), child=@table50)
  end

  def buildFrameRippingRelated
    @table60 = newTable(rows=2, columns=3)
#create objects
    @rip_label = Gtk::Label.new(_("Pass cdparanoia options:")) ; @rip_label.set_alignment(0.0, 0.5)
    @eject= Gtk::CheckButton.new(_('Eject cd when finished'))
    @noLog = Gtk::CheckButton.new(_('Only keep logfile if correction is needed'))
    @ripEntry= Gtk::Entry.new ; @ripEntry.width_request = 120
#pack objects
    @table60.attach(@rip_label, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table60.attach(@ripEntry, 1, 2, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 0, 0)
    @table60.attach(@eject, 0, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table60.attach(@noLog, 0, 2, 2, 3, Gtk::FILL|Gtk::SHRINK, Gtk::SHRINK, 0, 0)
    @frame60 = newFrame(_('Ripping related'), child=@table60)
#pack all frames into a single page
    @page1 = Gtk::VBox.new #One VBox to rule them all
    [@frame40, @frame50, @frame60].each{|frame| @page1.pack_start(frame,false,false)}
    @page1_label = Gtk::Label.new(_("Secure Ripping"))
    @display.append_page(@page1, @page1_label)
  end

  def buildFrameAudioSectorsBeforeTrackOne
    @tableToc1 = newTable(rows=3, columns=3)
#create objects
    @ripHiddenAudio = Gtk::CheckButton.new(_('Rip hidden audio sectors'))
    @markHiddenTrackLabel1 = Gtk::Label.new(_('Mark as a hidden track when bigger than'))
    @markHiddenTrackLabel2 = Gtk::Label.new(_('seconds'))
    @minLengthHiddenTrackSpin = Gtk::SpinButton.new(0, 30, 1)
    @minLengthHiddenTrackSpin.value = 2.0
    @ripHiddenAudio.tooltip_text = _("Uncheck this if cdparanoia crashes with your ripping drive.")
    text = _("A hidden track will rip to a seperate file if used in track modus.\nIf it's smaller the sectors will be prepended to the first track.")
    @minLengthHiddenTrackSpin.tooltip_text = text
    @markHiddenTrackLabel1.tooltip_text = text
    @markHiddenTrackLabel2.tooltip_text = text
#pack objects
    @tableToc1.attach(@ripHiddenAudio, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @tableToc1.attach(@markHiddenTrackLabel1, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @tableToc1.attach(@minLengthHiddenTrackSpin, 1, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @tableToc1.attach(@markHiddenTrackLabel2, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @ripHiddenAudio.signal_connect("clicked"){@minLengthHiddenTrackSpin.sensitive = @ripHiddenAudio.active?}
    @frameToc1 = newFrame(_('Audio sectors before track 1'), child=@tableToc1)
  end

  def buildFrameAdvancedTocAnalysis
    @tableToc2 = newTable(rows=3, columns=2)
    #create objects
    @createCue = Gtk::CheckButton.new(_('Create cuesheet'))
    @image = Gtk::CheckButton.new(_('Rip CD to single file'))
#pack objects
    @tableToc2.attach(@createCue, 0, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @tableToc2.attach(@image, 0, 2, 2, 3, Gtk::FILL|Gtk::SHRINK, Gtk::SHRINK, 0, 0)
    @vboxToc = Gtk::VBox.new()
    @vboxToc.pack_start(@tableToc2,false,false)
    @frameToc2 = newFrame(_('Advanced Toc analysis'), child=@vboxToc)
# build hbox for cdrdao
    @cdrdaoHbox = Gtk::HBox.new(false, 5)
    @cdrdao = Gtk::Label.new(_('Cdrdao installed?'))
    @cdrdaoImage = Gtk::Image.new(Gtk::Stock::CANCEL, Gtk::IconSize::BUTTON)
    @cdrdaoHbox.pack_start(@cdrdao, false, false, 5)
    @cdrdaoHbox.pack_start(@cdrdaoImage, false, false)
  end

  def buildFrameHandlingPregapsOtherThanTrackOne
    @tableToc3 = newTable(rows=3, columns=3)
#create objects
    @appendPregaps = Gtk::RadioButton.new(_('Append pregap to the previous track'))
    @prependPregaps = Gtk::RadioButton.new(@appendPregaps, _('Prepend pregaps to the track'))
#pack objects
    @tableToc3.attach(@appendPregaps, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @tableToc3.attach(@prependPregaps, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @frameToc3 = newFrame(_('Handling pregaps other than track 1'), child=@tableToc3)
    @vboxToc.pack_start(@frameToc3,false,false)
  end

  def buildFrameHandlingTracksWithPreEmphasis
    @tableToc4 = newTable(rows=3, columns=3)
#create objects
    @correctPreEmphasis = Gtk::RadioButton.new(_('Correct pre-emphasis tracks with sox'))
    @doNotCorrectPreEmphasis = Gtk::RadioButton.new(@correctPreEmphasis, _("Save the pre-emphasis tag in the cuesheet."))
#pack objects
    @tableToc4.attach(@correctPreEmphasis, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @tableToc4.attach(@doNotCorrectPreEmphasis, 0, 1, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @frameToc4 = newFrame(_('Handling tracks with pre-emphasis'), child=@tableToc4)
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
    if @deps.installed?('cdrdao')
      @cdrdaoImage.stock = Gtk::Stock::APPLY
      @frameToc2.each{|child| child.sensitive = true}
    else
      @cdrdaoImage.stock = Gtk::Stock::CANCEL
      @createCue.active = false
      @frameToc2.each{|child| child.sensitive = false}
    end
  end

  # signal for createCue
  def createCue
    @image.sensitive = @createCue.active?
    @image.active = false if !@createCue.active?
    @tableToc3.each{|child| child.sensitive = @createCue.active?}
    @tableToc4.each{|child| child.sensitive = @createCue.active?}
  end

  # signal for create single file
  def createSingle
    @tableToc3.each{|child| child.sensitive = !@image.active?}
    @correctPreEmphasis.active = true
    @doNotCorrectPreEmphasis.sensitive = !@image.active?
  end

  #set signals for the toc
  def setSignalsToc
    cdrdaoInstalled()
    createSingle()
    createCue()
    @createCue.signal_connect("clicked"){createCue()}
    @createCue.signal_connect("clicked"){`killall cdrdao 2>1` if !@createCue.active?}
    @image.signal_connect("clicked"){createSingle()}
  end

  def buildFrameSelectAudioCodecs # Select audio codecs frame
    @table70 = newTable(rows=6, columns=2)
#objects 1st column
    @flac = Gtk::CheckButton.new(_('Flac'))
    @vorbis = Gtk::CheckButton.new(_('Vorbis'))
    @mp3=  Gtk::CheckButton.new(_('Lame Mp3'))
    @wav = Gtk::CheckButton.new(_('Wav'))
    @other = Gtk::CheckButton.new(_('Other'))
    @expander70 = Gtk::Expander.new(_('Show options for "Other"'))
#objects 2nd column
    @flacEntry= Gtk::Entry.new()
    @vorbisEntry= Gtk::Entry.new()
    @mp3Entry= Gtk::Entry.new()
    @otherEntry= Gtk::Entry.new()
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
    @table70.attach(@flacEntry, 1, 2, 0, 1, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) #2nd column, 1st row
    @table70.attach(@vorbisEntry, 1, 2, 1, 2, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) #2nd column, 2nd row
    @table70.attach(@mp3Entry, 1, 2, 2, 3, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) # 2nd column, 3rd row
    @table70.attach(@otherEntry, 1, 2, 4, 5, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 0, 0) # 2nd column, 5th row
    @frame70 = newFrame(_('Select audio codecs'), child=@table70)
  end

  def buildFrameCodecRelated #Encoding related frame
    @table80 = newTable(rows=4, columns=2)
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
    @frame80 = newFrame(_('Codec related'), child=@table80)
  end

  def buildFrameNormalizeToStandardVolume #Normalize audio
    @table85 = newTable(rows=2, columns=1)
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
    @frame85 = newFrame(_('Normalize to standard volume'), child=@table85)
#pack all frames into a single page
    @page2 = Gtk::VBox.new #One VBox to rule them all
    [@frame70, @frame80, @frame85].each{|frame| @page2.pack_start(frame,false,false)}
    @page2_label = Gtk::Label.new(_("Codecs"))
    @display.append_page(@page2, @page2_label)
  end

  def freedbobjects_frame #Freedb client configuration frame
    @table90 = newTable(rows=5, columns=2)
#creating objects
    @enableFreedb= Gtk::CheckButton.new(_("Enable freedb metadata fetching"))
    @firstHit= Gtk::CheckButton.new(_("Always use first freedb hit"))
    @freedb_server_label= Gtk::Label.new(_("Freedb server:")) ; @freedb_server_label.set_alignment(0.0, 0.5)
    @freedb_username_label= Gtk::Label.new(_("Username:")) ; @freedb_username_label.set_alignment(0.0, 0.5)
    @freedb_hostname_label= Gtk::Label.new(_("Hostname:")) ; @freedb_hostname_label.set_alignment(0.0, 0.5)
    @freedbServerEntry = Gtk::Entry.new
    @freedbUsernameEntry = Gtk::Entry.new
    @freedbHostnameEntry = Gtk::Entry.new
#packing objects
    @table90.attach(@enableFreedb, 0, 2, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0) #both columns, 1st row
    @table90.attach(@firstHit, 0, 2, 1, 2, Gtk::FILL, Gtk::SHRINK, 0, 0) #both columns, 2nd row
    @table90.attach(@freedb_server_label, 0, 1, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 3rd row
    @table90.attach(@freedb_username_label, 0, 1, 3, 4, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 4th row
    @table90.attach(@freedb_hostname_label, 0, 1, 4, 5, Gtk::FILL, Gtk::SHRINK, 0, 0) #1st column, 5th row
    @table90.attach(@freedbServerEntry, 1, 2 , 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column, 3rd row
    @table90.attach(@freedbUsernameEntry, 1, 2, 3, 4, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column, 4th row
    @table90.attach(@freedbHostnameEntry, 1, 2, 4, 5, Gtk::FILL, Gtk::SHRINK, 0, 0) #2nd column, 5th row
    @frame90 = @frame80 = newFrame(_('Freedb options'), child=@table90)
#pack frame
    @page3 = Gtk::VBox.new #One VBox to rule them all
    [@frame90].each{|frame| @page3.pack_start(frame,false,false)}
    @page3_label = Gtk::Label.new(_("Freedb"))
    @display.append_page(@page3, @page3_label)
  end

  def buildFrameFilenamingScheme # Naming scheme frame
    @table100 = newTable(rows=6, columns=2)
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
    @basedirEntry = Gtk::Entry.new
    @namingNormalEntry = Gtk::Entry.new
    @namingVariousEntry = Gtk::Entry.new
    @namingImageEntry = Gtk::Entry.new
    @basedirEntry.signal_connect("key_release_event"){showFileNormal() ; false}
    @basedirEntry.signal_connect("button_release_event"){showFileNormal() ; false}
    @namingNormalEntry.signal_connect("key_release_event"){showFileNormal() ; false}
    @namingNormalEntry.signal_connect("button_release_event"){showFileNormal() ; false}
    @namingNormalEntry.signal_connect("focus-out-event"){if not File.dirname(@namingNormalEntry.text) =~ /%a|%b/ ; @namingNormalEntry.text = "%a (%y) %b/" + @namingNormalEntry.text; preventStupidness() end; false}
    @namingVariousEntry.signal_connect("key_release_event"){showFileVarious() ; false}
    @namingVariousEntry.signal_connect("button_release_event"){showFileVarious() ; false}
    @namingVariousEntry.signal_connect("focus-out-event"){if not File.dirname(@namingVariousEntry.text) =~ /%a|%b/ ; @namingVariousEntry.text = "%a (%y) %b/" + @namingVariousEntry.text; preventStupidness() end; false}
    @namingImageEntry.signal_connect("key_release_event"){showFileImage() ; false}
    @namingImageEntry.signal_connect("button_release_event"){showFileImage() ; false}
    @namingImageEntry.signal_connect("focus-out-event"){if not File.dirname(@namingImageEntry.text) =~ /%a|%b/ ; @namingImageEntry.text = "%a (%y) %b/" + @namingImageEntry.text; preventStupidness() end; false}
#packing 2nd column
    @table100.attach(@basedirEntry, 1, 2, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table100.attach(@namingNormalEntry, 1, 2, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table100.attach(@namingVariousEntry, 1, 2, 2, 3, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table100.attach(@namingImageEntry, 1, 2, 3, 4, Gtk::EXPAND|Gtk::FILL, Gtk::SHRINK, 0, 0)
    @frame100 = newFrame(_('Filenaming scheme'), child=@table100)
  end
  
  def showFileNormal
    @example_label.text = Preferences.showFilenameNormal( @basedirEntry.text, @namingNormalEntry.text)
  end
  
  def showFileVarious
    @example_label.text = Preferences.showFilenameVarious(
    @basedirEntry.text, @namingVariousEntry.text)
  end
  
  def showFileImage
    @example_label.text = Preferences.showFilenameVarious(
    @basedirEntry.text, @namingImageEntry.text)
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
  def buildFrameProgramsOfChoice
    @table110 = newTable(rows=2, columns=2)
#creating objects
    @editor_label = Gtk::Label.new(_("Log file viewer: ")) ; @editor_label.set_alignment(0.0, 0.5)
    @filemanager_label = Gtk::Label.new(_("File manager: ")) ; @filemanager_label.set_alignment(0.0,0.5)
    @editorEntry = Gtk::Entry.new
    @filemanagerEntry = Gtk::Entry.new
#packing objects
    @table110.attach(@editor_label, 0,1,0,1,Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table110.attach(@filemanager_label, 0,1,1,2,Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table110.attach(@editorEntry, 1,2,0,1, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @table110.attach(@filemanagerEntry, 1,2,1,2, Gtk::FILL, Gtk::SHRINK, 0, 0)
    @frame110 = newFrame(_('Programs of choice'), child=@table110)
  end

#Small table for debugging
#Verbose mode	| debug mode
  def buildFrameDebugOptions # Debug options frame
    @table120 = newTable(rows=1, columns=2)
#creating objects and packing them
    @verbose = Gtk::CheckButton.new(_('Verbose mode'))
    @debug = Gtk::CheckButton.new(_('Debug mode'))
    @table120.attach(@verbose, 0,1,0,1,Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK)
    @table120.attach(@debug, 1,2,0,1,Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK)
    @frame120 = newFrame(_('Debug options'), child=@table120)
  end

  def pack_other_frames #pack all frames into a single page
    @page4 = Gtk::VBox.new()
    [@frame100, @frame110, @frame120].each{|frame| @page4.pack_start(frame,false,false)}
    @page4_label = Gtk::Label.new(_("Other"))
    @display.signal_connect("switch_page") do |a, b, page|
      if page == 1
        cdrdaoInstalled()
      elsif page == 4
        showFileNormal()
      end
    end
    @display.append_page(@page4, @page4_label)
  end
end

