require 'test/unit/ui/console/testrunner'
require 'lib/log'
require 'basic_tests'
require 'pool_resize_tests'

if $dry_run
  info "Dry run mode.  Set the environment variable THIN_TESTS=EXECUTE" +
    " if you really want to run these tests"
end

ARGV << '-v'
