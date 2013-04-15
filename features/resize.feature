Feature: Resize

  As sys admin I want to be able to resize my volumes.

  Scenario: resize with no volume fails
    When I run `tvm resize`
    Then it should fail

  Scenario: --to
    Given a volume called "fred"
    When I run `tvm resize --to 1G fred`
    Then it should pass

  Scenario: --grow-by
    Given a volume called "fred"
    When I run `tvm resize --grow-by 1G fred`
    Then it should pass

  Scenario: --shrink-by
    Given a volume called "fred"
    When I run `tvm resize --shrink-by 1G fred`
    Then it should pass

  Scenario: --grow-to
    Given a volume called "fred"
    When I run `tvm resize --grow-to 1G fred`
    Then it should pass

  Scenario: --shrink-to
    Given a volume called "fred"
    When I run `tvm resize --shrink-to 1G fred`
    Then it should pass

  Scenario: Sizing options are mutually exclusive
    Given a volume called "fred"
    When I run `tvm resize --to 1G --grow-by 1G --grow-to 1G fred`
    Then it should fail

  Scenario: Size arguments must parse
    Given a volume called "fred"
    When I run `tvm resize --to size_inches fred`
    Then it should fail