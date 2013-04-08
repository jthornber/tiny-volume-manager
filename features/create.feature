Feature: create
  Scenario: create with no args fails
    Given no volumes
    When I run `tvm create`
    Then it should fail

  Scenario: create with more than one arg fails
    Given no volumes
    When I run `tvm create one two`
    Then it should fail

  Scenario: create succeeds
    Given no volumes
    When I run `tvm create fred`
    Then it should pass

  Scenario: create more than one volume succeeds
    Given no volumes
    When I run `tvm create foo`
    And I run `tvm create bar`
    Then it should pass

  Scenario: cannot create the same volume twice
    When I run `tvm create fred`
    And I run `tvm create fred`
    Then it should fail

  Scenario: create prints out the id of the new volume
    Given no volumes
    When I run `tvm create fred`
    Then the output should contain a uuid

  Scenario: creating two volumes gives them different ids
    Given no volumes
    When I create 3 volumes
    Then their ids should be different
