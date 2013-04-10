Feature: Transactionality

  As sys admin I want to be able to group together a set of commands
  and execute them atomically, or abort all of them.

  Scenario: Commit with no begin is an error
    Given no volumes
    When I run `tvm commit`
    Then it should fail with:
      """
      commit requested but not in transaction
      """

  Scenario: Abort with no begin is an error
    Given no volumes
    When I run `tvm abort`
    Then it should fail with:
      """
      abort requested but not in transaction
      """

  Scenario: begin once succeeds
    Given no volumes
    When I run `tvm begin`
    Then it should pass

  Scenario: begin whilst in transaction fails
    Given pending transaction
    When I run `tvm begin`
    Then it should fail with:
      """
      begin requested when already in transaction
      """

  Scenario: begin, commit, begin succeeds
    Given no volumes
    When I run `tvm begin`
    And I run `tvm commit`
    And I run `tvm begin`
    Then it should pass

  Scenario: begin, abort succeeds
    Given no volumes
    When I run `tvm begin`
    And I run `tvm abort`
    Then it should pass

  Scenario: begin, create, commit creates a volume
    Given no volumes
    When I run `tvm begin`
    And I run `tvm create fred`
    And I run `tvm commit`
    Then there should be a volume called "fred"

  Scenario: begin, create, abort does not create avolume
    Given no volumes
    When I run `tvm begin`
    And I run `tvm create fred`
    And I run `tvm abort`
    Then there should not be a volume called "fred"
