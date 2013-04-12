Feature: Snapshots
  Scenario: take a single snapshot
    Given a named volume
    When I take a snapshot
    Then it should pass

  Scenario: take several snapshots
    Given a named volume
    When I take a snapshot
    And I take a snapshot
    And I take a snapshot
    Then it should pass

  Scenario: snapshot of unkown volume fails
    When I take a snapshot
    Then it should fail
