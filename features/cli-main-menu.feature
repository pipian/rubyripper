Feature: Show a main menu after starting

  Scenario: Start Rubyripper
    Given no audio disc is inserted
    When I run `rubyripper_cli`
    Then it should pass with:
    """
    * RUBYRIPPER MAIN MENU *

    1) Change preferences
    2) Scan drive for audio disc
    3) Change metadata
    4) Select the tracks to rip (default = all)
    5) Rip the disc!
    99) Exit rubyripper...

    Please type the number of your choice [99] :
    """