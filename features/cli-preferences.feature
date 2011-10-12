Feature: Manage rubyripper preferences

  Scenario: Show the Preferences menu
    Given rubyripper will find "no audio disc" is inserted
    When I run rubyripper in cli mode
    And I choose "1" in order to get to the preferences menu
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
    Given rubyripper will find "no audio disc" is inserted
    When I run rubyripper in cli mode with default config
    And I choose "1" in order to get to the preferences menu
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