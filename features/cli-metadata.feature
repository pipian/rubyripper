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
