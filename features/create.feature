Feature: create
  Scenario: create with no args fails
    When I run `tvm create`
    Then it should fail

  Scenario: create with more than one arg fails
    When I run `tvm create one two`
    Then it should fail

  Scenario: create succeeds
    When I run `tvm create fred`
    Then there should be a volume called "fred"

  Scenario: create more than one volume succeeds
    When I run `tvm create foo`
    And I run `tvm create bar`
    Then there should be a volume called "foo"
    And there should be a volume called "bar"

  Scenario: cannot create the same volume twice
    When I run `tvm create fred`
    And I run `tvm create fred`
    Then it should fail

  Scenario: create prints out the id of the new volume
    When I run `tvm create fred`
    Then the output should contain a uuid

  Scenario: creating two volumes gives them different ids
    When I create 3 volumes
    Then their ids should be different
