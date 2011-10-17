@preferences
Feature: Manage rubyripper preferences

  Background:
    Given rubyripper will find "no audio disc" is inserted
    When I run rubyripper in cli mode with default config

  Scenario: Show the Preferences menu
    When I choose "1" in order to get to the preferences menu
    And I press ENTER "2" times to close the application
    Then the output should contain:
    """
    ** RUBYRIPPER PREFERENCES **

     1) Secure ripping
     2) Toc analysis
     3) Codecs
     4) Freedb
     5) Other
    99) Don't change any setting

    Please type the number of the setting you wish to change [99] : 
    """

  Scenario: Show the Secure Ripping submenu
    When I choose "1" in order to get to the preferences menu
    And I choose "1" in order to get to the secure ripping submenu
    And I press ENTER "3" times to close the application
    Then the output should contain:
    """
    *** SECURE RIPPING PREFERENCES ***

     1) Ripping drive: /dev/cdrom
     2) Drive offset: 0
        **Find your offset at http://www.accuraterip.com/driveoffsets.htm.
        **Your drive model is shown in the logfile.
     3) Passing extra cdparanoia parameters: -Z
     4) Match all chunks: 2
     5) Match erroneous chunks: 3
     6) Maximum trials: 7
     7) Eject disc after ripping [*]
     8) Only keep log when errors [ ]
    99) Back to settings main menu

    Please type the number of the setting you wish to change [99] : 
    """
    
    Scenario: Update the Secure Ripping Preferences
      When I choose "1" in order to get to the preferences menu
      And I choose "1" in order to get to the secure ripping submenu
      And I change each preferences item in the menu
        | 1 | /dev/dvdrom |
        | 2 | 100         |
        | 3 | -Z -Y       |
        | 4 | 3           |
        | 5 | 4           |
        | 6 | 8           |
        | 7 |             |
        | 8 |             |
      And I press ENTER "3" times to close the application
      Then the output should contain:
      """
      *** SECURE RIPPING PREFERENCES ***

       1) Ripping drive: /dev/dvdrom
       2) Drive offset: 100
          **Find your offset at http://www.accuraterip.com/driveoffsets.htm.
          **Your drive model is shown in the logfile.
       3) Passing extra cdparanoia parameters: -Z -Y
       4) Match all chunks: 3
       5) Match erroneous chunks: 4
       6) Maximum trials: 8
       7) Eject disc after ripping [ ]
       8) Only keep log when errors [*]
      99) Back to settings main menu

      Please type the number of the setting you wish to change [99] : 
      """
      
    Scenario: Show the Toc Analysis submenu
      When I choose "1" in order to get to the preferences menu
      And I choose "2" in order to get to the toc analysis submenu
      And I press ENTER "3" times to close the application
      Then the output should contain:
      """
      *** TOC ANALYSIS PREFERENCES ***

       1) Create a cuesheet [*]
       2) Rip to single file [ ]
       3) Rip hidden audio sectors [*]
       4) Minimum seconds hidden track: 2
       5) Append or prepend audio: prepend
       6) Way to handle pre-emphasis: cue
      99) Back to settings main menu

      Please type the number of the setting you wish to change [99] : 
      """
      
    Scenario: Update the Toc Analysis Preferences
      When I choose "1" in order to get to the preferences menu
      And I choose "2" in order to get to the toc analysis submenu
      And I change each preferences item in the menu
        | 1 |             |
        | 2 |             |
        | 3 |             |
        | 4 | 3           |
        | 5 | 2           |
        | 6 | 2           |
      And I press ENTER "3" times to close the application
      Then the output should contain:
      """
      *** TOC ANALYSIS PREFERENCES ***

       1) Create a cuesheet [ ]
       2) Rip to single file [*]
       3) Rip hidden audio sectors [ ]
       4) Minimum seconds hidden track: 3
       5) Append or prepend audio: append
       6) Way to handle pre-emphasis: sox
      99) Back to settings main menu

      Please type the number of the setting you wish to change [99] : 
      """

    Scenario: Show the Codecs submenu
      When I choose "1" in order to get to the preferences menu
      And I choose "3" in order to get to the codecs submenu
      And I press ENTER "3" times to close the application
      Then the output should contain:
      """
      *** CODEC PREFERENCES ***

       1) Flac [ ]
       2) Flac options passed: --best -V
       3) Vorbis [*]
       4) Oggenc options passed: -q 4
       5) Mp3 [ ]
       6) Lame options passed: -V 3 --id3v2-only
       7) Wav [ ]
       8) Other codec [ ]
       9) Commandline passed: flac %i %o.flac
      10) Playlist support [*]
      11) Maximum extra encoding threads: 2
      12) Replace spaces with underscores [ ]
      13) Downsize all capital letters in filenames [ ]
      14) Normalize program: none
      15) Normalize modus: album
      99) Back to settings main menu

      Please type the number of the setting you wish to change [99] : 
      """

    Scenario: Update the Codecs Preferences
      When I choose "1" in order to get to the preferences menu
      And I choose "3" in order to get to the codecs submenu
      And I change each preferences item in the menu
        | 1  |                    |
        | 2  | --fast -V          |
        | 3  |                    |
        | 4  | -q 5               |
        | 5  |                    |
        | 6  | -V 4               |
        | 7  |                    |
        | 8  |                    |
        | 9  | lame "%i" "%o".mp3 |
        | 10 |                    |
        | 11 | 3                  |
        | 12 |                    |
        | 13 |                    |
        | 14 | 2                  |
        | 15 | 2                  |
      And I press ENTER "3" times to close the application
      Then the output should contain:
      """
      *** CODEC PREFERENCES ***

       1) Flac [*]
       2) Flac options passed: --fast -V
       3) Vorbis [ ]
       4) Oggenc options passed: -q 5
       5) Mp3 [*]
       6) Lame options passed: -V 4
       7) Wav [*]
       8) Other codec [*]
       9) Commandline passed: lame "%i" "%o".mp3
      10) Playlist support [ ]
      11) Maximum extra encoding threads: 3
      12) Replace spaces with underscores [*]
      13) Downsize all capital letters in filenames [*]
      14) Normalize program: replaygain
      15) Normalize modus: track
      99) Back to settings main menu

      Please type the number of the setting you wish to change [99] : 
      """
      
    Scenario: Show the Freedb submenu
      When I choose "1" in order to get to the preferences menu
      And I choose "4" in order to get to the freedb submenu
      And I press ENTER "3" times to close the application
      Then the output should contain:
      """
      *** FREEDB PREFERENCES ***

       1) Fetch cd info with freedb [*]
       2) Always use first hit [*]
       3) Freedb server: http://freedb.freedb.org/~cddb/cddb.cgi
       4) Freedb username: anonymous
       5) Freedb hostname: my_secret.com
      99) Back to settings main menu

      Please type the number of the setting you wish to change [99] : 
      """

    Scenario: Update the Freedb Preferences
      When I choose "1" in order to get to the preferences menu
      And I choose "4" in order to get to the freedb submenu
      And I change each preferences item in the menu
        | 1  |                    |
        | 2  |                    |
        | 3  | www.google.nl      |
        | 4  | joe                |
        | 5  | dalton.com         |
      And I press ENTER "3" times to close the application
      Then the output should contain:
      """
      *** FREEDB PREFERENCES ***

       1) Fetch cd info with freedb [ ]
       2) Always use first hit [ ]
       3) Freedb server: www.google.nl
       4) Freedb username: joe
       5) Freedb hostname: dalton.com
      99) Back to settings main menu

      Please type the number of the setting you wish to change [99] : 
      """
      
    Scenario: Show the Other submenu
      When I choose "1" in order to get to the preferences menu
      And I choose "5" in order to get to the other submenu
      And I press ENTER "3" times to close the application
      Then the output should contain:
      """
      *** OTHER PREFERENCES ***

       1) Base directory: ~/
       2) Standard filescheme: %f/%a (%y) %b/%n - %t
       3) Various artist filescheme: %f/%va (%y) %b/%n - %a - %t
       4) Single file rip filescheme: %f/%a (%y) %b/%a - %b (%y)
       5) Log file viewer: mousepad
       6) File manager: thunar
       7) Verbose mode [ ]
       8) Debug mode [ ]
      99) Back to settings main menu

      Please type the number of the setting you wish to change [99] : 
      """
    
    Scenario: Update the Other Preferences
      When I choose "1" in order to get to the preferences menu
      And I choose "5" in order to get to the other submenu
      And I change each preferences item in the menu
        | 1  | /home/test         |
        | 2  | test               |
        | 3  | test2              |
        | 4  | test3              |
        | 5  | leafpad            |
        | 6  | dolphin            |
        | 7  |                    |
        | 8  |                    |
      And I press ENTER "3" times to close the application
      Then the output should contain:
      """
      *** OTHER PREFERENCES ***

       1) Base directory: ~/
       2) Standard filescheme: %f/%a (%y) %b/%n - %t
       3) Various artist filescheme: %f/%va (%y) %b/%n - %a - %t
       4) Single file rip filescheme: %f/%a (%y) %b/%a - %b (%y)
       5) Log file viewer: mousepad
       6) File manager: thunar
       7) Verbose mode [ ]
       8) Debug mode [ ]
      99) Back to settings main menu

      Please type the number of the setting you wish to change [99] : 
      """  