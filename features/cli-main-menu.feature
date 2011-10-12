Feature: Show an interactive main menu after starting

  Scenario: Start Rubyripper
    Given rubyripper will find "no audio disc" is inserted
    When I run rubyripper in cli mode
    And I choose "99" in order to close the application
    Then the output should contain:
    """
    WARNING: There is no audio disc ready in drive /dev/cdrom.

    * RUBYRIPPER MAIN MENU *

     1) Change preferences
     2) Scan drive for audio disc
     3) Change metadata
     4) Select the tracks to rip (default = all)
     5) Rip the disc!
    99) Exit rubyripper...

    Please type the number of your choice [99] : Thanks for using rubyripper.
    Have a nice day!
    """