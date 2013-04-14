Feature: Resize
  
  As sys admin I want to be able to resize my volumes.

  Scenario: resize with no volume fails
    When I run `tvm resize`
    Then it should fail

  Scenario: --to-size
    Given a volume called "fred"
    When I run `tvm resize --to-size 1G fred`
    Then it should pass