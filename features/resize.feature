Feature: Resize

  As sys admin I want to be able to resize my volumes.

  Scenario: resize with no volume fails
    When I run `tvm resize`
    Then it should fail

  Scenario: --size
    Given a volume called "fred"
    When I run `tvm resize --size 1GB fred`
    Then it should pass

  Scenario: --grow-by
    Given a volume called "fred"
    When I run `tvm resize --grow-by 1GB fred`
    Then it should pass

  Scenario: --shrink-by
    Given a volume called "fred"
    When I run `tvm resize --shrink-by 1GB fred`
    Then it should pass

  Scenario: --grow-to
    Given a volume called "fred"
    When I run `tvm resize --grow-to 1GB fred`
    Then it should pass

  Scenario: --shrink-to
    Given a volume called "fred"
    When I run `tvm resize --shrink-to 1GB fred`
    Then it should pass

  Scenario: Sizing options are mutually exclusive
    Given a volume called "fred"
    When I run `tvm resize --size 1GB --grow-by 1GB --grow-to 1GB fred`
    Then it should fail

  Scenario: Size arguments must parse
    Given a volume called "fred"
    When I run `tvm resize --size last_week fred`
    Then it should fail

  Scenario: Resize takes just one volume arg
    Given a volume called "fred"
    And a volume called "barney"
    When I run `tvm resize --size 1GB fred barney`
    Then it should fail

  Scenario: --size correctly sets the size
    Given a volume called "fred"
    When I run `tvm resize --size 1GB fred`
    Then "fred" should have size 1GB

  @announce
  Scenario: --grow-by correctly extends
    Given a volume called "fred"
    And "fred" has size 1GB
    When I run `tvm resize --grow-by 1GB fred`
    Then "fred" should have size 2GB

