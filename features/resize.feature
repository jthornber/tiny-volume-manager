Feature: Resize

  As sys admin I want to be able to resize my volumes.

  Scenario: resize with no volume fails
    When I tvm resize
    Then it should fail

  Scenario: --size
    Given a volume called "fred"
    When I tvm resize --size 1GB fred
    Then it should pass

  Scenario: --grow-to
    Given a volume called "fred"
    When I tvm resize --grow-to 1GB fred
    Then it should pass

  Scenario: --shrink-to
    Given a volume called "fred"
    When I tvm resize --shrink-to 1GB fred
    Then it should pass

  Scenario: Sizing options are mutually exclusive
    Given a volume called "fred"
    When I tvm resize --size 1GB --grow-by 1GB --grow-to 1GB fred
    Then it should fail

  Scenario: Size arguments must parse
    Given a volume called "fred"
    When I tvm resize --size last_week fred
    Then it should fail

  Scenario: Resize takes just one volume arg
    Given a volume called "fred"
    And a volume called "barney"
    When I tvm resize --size 1GB fred barney
    Then it should fail

  Scenario: --size correctly sets the size
    Given a volume called "fred"
    When I tvm resize --size 1GB fred
    Then "fred" should have size 1GB

  Scenario: --grow-by extends
    Given a volume called "fred"
    And "fred" has size 1GB
    When I tvm resize --grow-by 1GB fred
    Then "fred" should have size 2GB

  Scenario: --shrink-by shrinks
    Given a volume called "fred"
    And "fred" has size 2GB
    When I tvm resize --shrink-by 1GB fred
    Then "fred" should have size 1GB

  Scenario: --shrink-by raises an error if new size would be negative
    Given a volume called "fred"
    And "fred" has size 2GB
    When I tvm resize --shrink-by 3GB fred
    Then it should fail

