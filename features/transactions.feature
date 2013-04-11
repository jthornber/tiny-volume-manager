Feature: Transactionality

  As sys admin I want to be able to group together a set of commands
  and execute them atomically, or abort all of them.

  Scenario: Commit with no changes is an error
    When I run `tvm commit`
    Then it should fail with:
      """
      commit requested but no pending changes
      """

  Scenario: (create => commit => create => commit) succeeds
    When I run `tvm create foo`
    And I run `tvm commit`
    And I run `tvm create bar`
    And I run `tvm commit`
    Then it should pass

  Scenario: abort succeeds
    And I run `tvm abort`
    Then it should pass

  Scenario: (create => commit) creates a volume
    And I run `tvm create fred`
    And I run `tvm commit`
    Then there should be a volume called "fred"

  Scenario: (create => abort) does not create a volume
    And I run `tvm create fred`
    And I run `tvm abort`
    Then there should not be a volume called "fred"
