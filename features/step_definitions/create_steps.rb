require 'set'

DEFAULT_NAME='debian-image'

Given(/^a named volume$/) do
  run_simple "tvm create #{DEFAULT_NAME}"
end

Given(/^a volume called "(.*?)"$/) do |name|
  in_current_dir do
    vm.begin unless !vm.metadata.in_transaction?
    vm.create_volume(name: name)
  end
end


Then(/^it should pass$/) do
  assert_success(true)
end

When(/^I create (#{COUNT}) volumes$/) do |nr_volumes|
  in_current_dir do
    1.upto(nr_volumes) do |n|
      run_simple "tvm create #{DEFAULT_NAME}_#{n}"
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
