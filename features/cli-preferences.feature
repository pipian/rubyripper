Feature: Manage rubyripper preferences

  Scenario: Show the preferences submenu
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