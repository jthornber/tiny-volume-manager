@announce
Feature: list
  Scenario: displays a line for each volume
    Given 3 volumes
    When I run `tvm list`
    Then it should pass
    And the output should be 3 lines long

  Scenario: names are displayed if defined
    Given a volume named "fred"
    When I run `tvm list`
    Then it should pass
    And the output should contain "fred"

  Scenario: snapshots of a volume are displayed indented
    Given a volume named "fred"
    And 3 snapshots of "fred"
    When I run `tvm list`
    Then it should pass
    And the output should contain "fred"
    And 3 lines matching /^\s+/

  Scenario: Every volume should have a creation time
    Given a named volume
    And I have tweaked the io wait var
    When I run `tvm list`
    Then the output should contain a time