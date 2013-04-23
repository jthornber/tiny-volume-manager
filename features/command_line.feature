Feature: General command line support

  @announce
  Scenario: --help prints usage to stdout
    When I tvm --help
    Then the stdout should contain:
      """
      tiny volume manager
        --help, -h:   Show this message
      """

  Scenario: Unknown sub commands cause fail
    When I tvm unleashtheearwigs
    Then it should fail
    And the stderr should contain:
    """
    unknown command 'unleashtheearwigs'
    """