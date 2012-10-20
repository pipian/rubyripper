# encoding: utf-8
@metadata
Feature: See and update the metadata from audio discs

  Scenario: Show the metadata
    Given rubyripper will find "Motorhead/Inferno" is inserted
    When I run rubyripper in cli mode with default config
    And I choose "99" in order to close the application
    Then the output should contain:
    """
    
    AUDIO DISC FOUND
    Number of tracks: 12
    Total playtime: 48:32
    
    DISC INFO
    Artist: Motorhead
    Album: Inferno
    Genre: Metal
    Year: 2004
    Extra disc info: YEAR: 2004
    Marked as various disc? [ ]
    
    TRACK INFO
    1. Terminal Show
    2. Killers
    3. In The Name Of Tragedy
    4. Suicide
    5. Life's A Bitch
    6. Down On Me
    7. In The Black
    8. Fight
    9. In The Year Of The Wolf
    10. Keys To The Kingdom
    11. Smiling Like A Killer
    12. Whorehouse Blues

    """

  Scenario: Convert iso-8859-1 (latin) encoded metadata to UTF-8
    Given rubyripper will find "aLatinEncodedDisc" is inserted
    When I run rubyripper in cli mode with default config
    And I choose "99" in order to close the application
    Then the output should contain:
    """
    
    AUDIO DISC FOUND
    Number of tracks: 5
    Total playtime: 48:32
    
    DISC INFO
    Artist: Die Ärzte
    Album: Ein Schwein namens Männer
    Genre: Deutsch
    Year: 1998
    Extra disc info: Walt Disney Records 1997WD360592 YEAR: 1998
    Marked as various disc? [ ]
    
    TRACK INFO
    1. Männer sind Schweine (Single Version)
    2. Du bist nicht mein Freund
    3. Saufen
    4. Ein Lächeln (für jeden Tag deines Lebens)
    5. Männer sind Schweine (Jetzt noch kürzer!)
    
    """