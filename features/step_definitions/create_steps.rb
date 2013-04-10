require 'set'

DEFAULT_NAME='debian-image'

# I think this is redundant since every scenario starts with a new dir
Given(/^no volumes$/) do
  in_current_dir do
    `rm -f volumes.yaml`
  end
end

Given(/^a named volume$/) do
  run "tvm create #{DEFAULT_NAME}"
end

Then(/^it should pass$/) do
  assert_success(true)
end

When(/^I create (#{COUNT}) volumes$/) do |nr_volumes|
  in_current_dir do
    1.upto(nr_volumes) do |n|
      run "tvm create #{DEFAULT_NAME}_#{n}"
    end
  end
end

Then(/^their ids should be different$/) do
  seen = Set.new

  all_output.lines do |line|
    line.chomp!
    seen.member?(line).should be_false
    seen << line
  end
end

Then(/^it should fail$/) do
  assert_success(false)
end

Then(/^the output should contain a uuid$/) do
  assert_matching_output('[0-9a-f]{16}', all_output)
end

Then(/^there should be a volume called "(.*?)"$/) do |name|
  assert_success(true)
  in_current_dir do
    vm.volume_by_name(name).should_not be_nil
  end
end

Then(/^there should not be a volume called "(.*?)"$/) do |name|
  assert_success(true)
  in_current_dir do
    expect {vm.volume_by_name(name)}.to raise_error(RuntimeError, Regexp.new(name))
  end
end