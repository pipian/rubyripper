#!/usr/bin/env ruby
# coding: utf-8
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

require 'rubyripper/freedb/freedbResultParser.rb'

# A class to test if to_be_tested_ruby_file does <X> correctly
class TC_FreedbResultParser < Test::Unit::TestCase
	# make all instances necessary only once
	def setup
		@file001 = getFile(File.join($localdir, 'data/freedb/disc001'))
		@file002 = getFile(File.join($localdir, 'data/freedb/disc002'))
		@file003 = getFile(File.join($localdir, 'data/freedb/disc003'))
		@file004 = getFile(File.join($localdir, 'data/freedb/disc004'))
		@file005 = getFile(File.join($localdir, 'data/freedb/disc005'))
		@file006 = getFile(File.join($localdir, 'data/freedb/disc006'))
		@inst001 = FreedbResultParser.new(@file001)
		@inst002 = FreedbResultParser.new(@file002)
		@inst003 = FreedbResultParser.new(@file003)
		@inst004 = FreedbResultParser.new(@file004)
		@inst005 = FreedbResultParser.new(@file005)
		@inst006 = FreedbResultParser.new(@file006)
	end

	# file helper because of different encoding madness, it should be UTF-8
	# The only plausible way to test this is reloading the file
	# String manipulation afterwards seems not possible
	# Ruby 1.8 does not have encoding support yet
	def getFile(path)
		freedb = String.new
		if freedb.respond_to?(:encoding)
			File.open(path, 'r:utf-8') do |file|
				freedb = file.read()
			end
		
			return freedb if freedb.valid_encoding?
	
			File.open(path, 'r:iso-8859-1') do |file|
				freedb = file.read()
			end
			
			if not freedb.valid_encoding?
				raise EncodingError, 'The encoding of the freedb file can not be determined'
			end

			return freedb.encode('UTF-8')
		else
			freedb = File.read(path)
		end
	end

	# run all tests, all functions that start with test are loaded
	def testSuite
		instance001()
		instance002()
		instance003()
		instance004()
		instance005()
		instance006()
	end

	# test if inst001 passes (normal audio disc, single artist)
	def instance001
		assert_equal(_('ok'), @inst001.status)
		assert_equal('98113b0e', @inst001.getInfo('discid'))
		assert_equal('Type O Negative', @inst001.getInfo('artist'))
		assert_equal('Bloody Kisses', @inst001.getInfo('album'))
		assert_equal('1993', @inst001.getInfo('year'))
		assert_equal('Gothic', @inst001.getInfo('genre'))
		{1=>'Machine Screw', 2=>'Christian Woman', 
3=>'Black No.1 (Little Miss Scare-All)', 4=>'Fay Wray Come Out and Play', 
5=>'Kill All the White People', 6=>'Summer Breeze', 7=>'Set Me on Fire', 
8=>'Dark Side of the Womb', 9=>'We Hate Everyone', 
10=>'Bloody Kisses (A Death in the Family)', 11=>'3.0.I.F', 12=>'Too Late: Frozen',
13=>'Blood & Fire', 14=>'Can\'t Lose You'}.each do |key, value|
			assert_equal(value, @inst001.getInfo('tracklist')[key])
		end
		assert_equal(false, @inst001.getInfo('extraDiscInfo'))
		assert_equal(false, @inst001.getInfo('oldTracklist'))
	end

	# test if inst002 passes (audio disc with extra disc info)
	def instance002
		assert_equal(_('ok'), @inst002.status)
		assert_equal('8d093509', @inst002.getInfo('discid'))
		assert_equal('Judas Priest', @inst002.getInfo('artist'))
		assert_equal('Sad Wings Of Destiny', @inst002.getInfo('album'))
		assert_equal('1976', @inst002.getInfo('year'))
		assert_equal('Rock', @inst002.getInfo('genre'))
		{1=>'Victim Of Changes', 2=>'The Ripper', 3=>'Dreamer Deceiver', 
4=>'Deceiver', 5=>'Prelude', 6=> 'Tyrant', 7=>'Genocide', 8=>'Epitaph', 
9=>'Island Of Domination'}.each do |key, value|
			assert_equal(value, @inst002.getInfo('tracklist')[key])
		end
		assert_equal("P 1976 Gull Records\\nC 1995 Repertoire Records\\n\\nRobert \
Halfordt- vocals\\nGlenn Tiptont- guitar\\nK. K. Downingt- guitar\\nIan Hilltt- \
bass\\nAlan Mooret- drums", @inst002.getInfo('extraDiscInfo'))
		assert_equal(false, @inst002.getInfo('oldTracklist'))
	end

	# test if inst003 passes (various artist disc with / separator)
	def instance003
		assert_equal(_('ok'), @inst003.status)
		assert_equal('0a0dd914', @inst003.getInfo('discid'))
		assert_equal('Various', @inst003.getInfo('artist'))
		assert_equal('Années 60 CD1', @inst003.getInfo('album'))
		assert_equal('2004', @inst003.getInfo('year'))
		assert_equal('Misc', @inst003.getInfo('genre'))
		{1=>'Baby Come Back', 2=>'No Milk Today', 3=> 'In The Summertime', 
4=>'Friday on my Mind', 5=>'The Letter', 6=>'Black is Black', 
7=>'House of The Rising Sun', 8=>'Leader Of The Pack', 9=>'Happy Together', 
10=>'Speedy Gonzales', 11=>'Papa Oom Mow Mow', 12=>'The Lion Sleeps Tonight',
13=>'Ob-La-DI, Ob-La-Da', 14=>'Ya Ya', 15=>'Save The Last Dance For Me',
16=>'Michelle', 17=>'Let\'s Dance', 18=>'Lets Go In yon Francisco', 
19=>'Raindrops Keep Fallin\' On My Head', 20=>'Suddenly You Love Me'}.each do |key, value|
			assert_equal(value, @inst003.getInfo('tracklist')[key])
		end
		{1=>'THE EQUALS', 2=>'HERMAN HERMITS', 3=>'MUNGO JERRY', 4=>'THE EASYBEATS', 
5=>'THE BOX TOPS', 6=>'LOS BRAVOS', 7=>'THE ANIMALS', 8=>'THE SHANGRI LAS', 
9=>'THE TURTLES', 10=>'PAT BOONE', 11=>'THE RIVINGTONS', 12=>'THE TOKENS', 
13=>'MARMALADE', 14=>'THE SAVAGE YOUNG BEATLES', 15=>'THE DRIFTERS', 16=>'THE OVERLANDERS', 17=>'THE SAVAGE YOUNG BEATLES', 18=>'TONY BURROWS OF THE FLOWERPOT MEN', 
19=>'BJ THOMAS', 20=>'THE TREMOLOES'}.each do |key, value|
			assert_equal(value, @inst003.getInfo('varArtist')[key])
		end
		assert_equal(false, @inst003.getInfo('extraDiscInfo'))

		# test if the original message is saved
		# this either works or not, so it's only tested once
		{1=>'THE EQUALS / Baby Come Back', 2=>'HERMAN HERMITS / No Milk Today',
3=>'MUNGO JERRY / In The Summertime', 4=>'THE EASYBEATS / Friday on my Mind',
5=>'THE BOX TOPS / The Letter', 6=>'LOS BRAVOS / Black is Black',
7=>'THE ANIMALS / House of The Rising Sun', 8=>'THE SHANGRI LAS / Leader Of The Pack',
9=>'THE TURTLES / Happy Together', 10=>'PAT BOONE / Speedy Gonzales',
11=>'THE RIVINGTONS / Papa Oom Mow Mow', 12=>'THE TOKENS / The Lion Sleeps Tonight',
13=>'MARMALADE / Ob-La-DI, Ob-La-Da', 14=>'THE SAVAGE YOUNG BEATLES / Ya Ya',
15=>'THE DRIFTERS / Save The Last Dance For Me', 16=>'THE OVERLANDERS / Michelle',
17=>'THE SAVAGE YOUNG BEATLES / Let\'s Dance',
18=>'TONY BURROWS OF THE FLOWERPOT MEN / Lets Go In yon Francisco',
19=>'BJ THOMAS / Raindrops Keep Fallin\' On My Head',
20=>'THE TREMOLOES / Suddenly You Love Me'}.each do |key, value|
			assert_equal(value, @inst003.getInfo('oldTracklist')[key])
		end		
	end

	#test if inst004 passes (disc with multiple rows per track and title)
	def instance004
		assert_equal(_('ok'), @inst004.status)
		assert_equal('0a0f5811', @inst004.getInfo('discid'))
		assert_equal('Maria Venuti', @inst004.getInfo('artist'))
		assert_equal('Maria Venuti Sings Schubert, Schoenberg, Schumann', @inst004.getInfo('album'))
		assert_equal('1994', @inst004.getInfo('year'))
		assert_equal('Classical', @inst004.getInfo('genre'))
		{1=>'Der Hirt Auf Dem Flesen Op. 129 (Studio)', 
2=>'4 Lieder Nach Texten V. Richard Dehmel Op. 2: Erwartung', 
3=>'4 Lieder Nach Texten V. Richard Dehmel Op. 2: Schenk Mir Deinen Goldenen Kamm',
4=>'4 Lieder Nach Texten V. Richard Dehmel Op. 2: Erhebung', 
5=>'4 Lieder Nach Texten V. Richard Dehmel Op. 2: Waldsonne',
6=>'4 Lieder Der Mignon Nach Goethe: Kennst Du Das Land Op. 62, No. 1',
7=>'4 Lieder Der Mignon Nach Goethe: Nur Wer Die Sehnsucht Kennt Op. 62, No. 4',
8=>'4 Lieder Der Mignon Nach Goethe: Heiss Mich Nicht Reden Op. 62, No. 2',
9=>'4 Lieder Der Mignon Nach Goethe: So Lasst Mich Scheinen Op. 62, No. 3',
10=>'4 Lieder Der Mignon Nach Goethe: Kennst Du Das Land',
11=>'4 Lieder Der Mignon Nach Goethe: Nur Wer Die Sehnsucht Kennt',
12=>'4 Lieder Der Mignon Nach Goethe: Heiss Mich Nicht Reden',
13=>'4 Lieder Der Mignon Nach Goethe: So Lasst Mich Scheinen',
14=>'Franz Schubert: Suleika Op. 14',
15=>'Franz Schubert: Suleikas Zweiter Gesang Op. 31',
16=>'Franz Schubert: Florio Op. 124, No. 2',
17=>'Franz Schubert: Delphine Op. 124, No. 1'}.each do |key, value|
			assert_equal(value, @inst004.getInfo('tracklist')[key])
		end
		assert_equal(false, @inst004.getInfo('extraDiscInfo'))
		assert_equal(false, @inst004.getInfo('oldTracklist'))
	end

	# test if inst005 passes (various artist disc with - separator)
	def instance005
		assert_equal(_('ok'), @inst005.status)
		assert_equal('0a105e12', @inst005.getInfo('discid'))
		assert_equal('Sampler Klezmer', @inst005.getInfo('artist'))
		assert_equal('Doyres (Generations)', @inst005.getInfo('album'))
		assert_equal(false, @inst005.getInfo('year'))
		assert_equal('Klezmer', @inst005.getInfo('genre'))
		{1=>'Bucharest', 2=>'Gypsy hora and sirba', 3=>'Opshpiel far di Makhutonim',
4=>'Another glass of wine', 5=>'Moldavian hora', 6=>'No name sirba',
7=>'Husid\'l Medley', 8=>'Dovid, shpil es nokh amol', 9=>'Ot Azoy!',
10=>'A Doinele', 11=>'Hora and sirba', 12=>'Meron arabesque', 13=>'Shabes Nign',
14=>'Greeting of the bride', 15=>'Freilik', 16=>'Oy, di Kinderlakh!',
17=>'Unzer Toyrele', 18=>'Oy Tate - Serbe romanya - Lebn zol Palestina'}.each do |key, value|
			assert_equal(value, @inst005.getInfo('tracklist')[key])
		end
		{1=>'Klezmorim, The', 2=>'Feldman, Zev & Andy Statman', 3=>'Tarras, Dave',
4=>'Statman Klezmer Orchestra, The Andy', 5=>'Kapelye',
6=>'Rubin, Joel & The Epstein Brothers Orchestra', 7=>'Klezmer Plus!',
8=>'Klezmer Conservatory Band', 9=>'Rubin Klezmer Band, Joel', 
10=>'New York Klezmer Ensemble', 11=>'Epstein Brothers Orchestra, The', 
12=>'Berlin, Musa', 13=>'Rubin & Horowitz', 14=>'Muszikás', 
15=>'Ukrainian Brass Band From Vinnitsa, The', 16=>'Chicago Klezmer Ensemble',
17=>'Kapelye', 18=>'New Shtetl Band'}.each do |key, value|
			assert_equal(value, @inst005.getInfo('varArtist')[key])
		end
		assert_equal(false, @inst005.getInfo('extraDiscInfo'))
	end

	# test if inst006 passes (various artist disc with : separator)
	# also with ISO-8859-1 encoding
	def instance006
		assert_equal(_('ok'), @inst006.status)
		assert_equal('1c11c714', @inst006.getInfo('discid'))
		assert_equal('Various', @inst006.getInfo('artist'))
		assert_equal('Jazz Manouche CD 1', @inst006.getInfo('album'))
		assert_equal(false, @inst006.getInfo('year'))
		assert_equal('Jazz', @inst006.getInfo('genre'))
		{1=>'New York City', 2=>'Flèche D\'or', 3=>'Undecided', 4=>'Jo\'s Remake',
5=>'Cherokee', 6=>'Stompin\' At Decca', 7=>'Joseph\'s Tiger', 8=>'Minor Swing',
9=>'Bleu Citron', 10=>'Djangologie', 11=>'Complices', 12=>'After You\'ve Gone',
13=>'Les Yeux Noirs', 14=>'J\'attendrai', 15=>'Où Es Tu Mon Amour', 16=>'S\'wonderful',
17=>'Oh, Lady, Be Good (live In Paris 1992)', 18=>'La Bande Des Trois',
19=>'Twelth Year', 20=>'Manoir De Mes Rêves'}.each do |key, value|
			assert_equal(value, @inst006.getInfo('tracklist')[key])
		end
		{1=>'Bireli Lagrène', 2=>'Angelo Debarre Quartet', 3=>'Tchavolo Schmitt',
4=>'Romane', 5=>'Gyppsy Guitars', 6=>'Mandino Reinhardt', 7=>'Stochelo Rosenberg',
8=>'New Quintet Du Hot Club De France', 9=>'Dorado Schmitt', 10=>'Babik Reinhardt',
11=>'Note Manouche', 12=>'Romane', 13=>'Tchan Tchou Vidal', 14=>'Moreno',
15=>'Christian Escoudé, Dorado Schmitt, Babik Reinhardt', 
# There is a ruby bug which prevent decoding the Ž, therefore replace it with what is found
#16=>'HänsŽche Weiss Quartett', 17=>'Stéphane Grappelli', 18=>'Boulou',
16=>'Häns´che Weiss Quartett', 17=>'Stéphane Grappelli', 18=>'Boulou',
19=>'Fapy Lafertin',
20=>'Le Quintette Du Hot Club De France, Django Reinhardt'}.each do |key, value|
			assert_equal(value, @inst006.getInfo('varArtist')[key])
		end
		assert_equal(false, @inst006.getInfo('extraDiscInfo'))
	end
end
