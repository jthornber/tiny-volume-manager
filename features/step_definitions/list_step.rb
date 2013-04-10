Given(/^(#{COUNT}) volumes$/) do |nr_volumes|
  in_current_dir do
    vm.wipe

    vm.begin
    1.upto(nr_volumes) do |n|
      vm.create_volume
    end
    vm.commit
  end
end

Given(/^a volume named "(.*?)"$/) do |vol|
  in_current_dir do
    vm.begin
    vm.create_volume(name: vol)
    vm.commit
  end
end

Given(/^(#{COUNT}) snapshots of "(.*?)"$/) do |nr_snaps, vol|
  in_current_dir do
    vm.begin
    1.upto(nr_snaps) {vm.snap_volume(vol)}
    vm.commit
  end
end

# FIXME: debug aid, doesn't seem to have any effect
Given(/^I have tweaked the io wait var$/) do
  @aruba_io_wait_seconds=0.1
  @aruba_timeout_seconds=10
end

Then(/^(#{COUNT}) lines matching \/(.*?)\/$/) do |nr_matches, pattern|
  count = 0
  rx = Regexp.new(pattern)

  all_output.lines.each do |line|
    count += 1 if line =~ rx
  end

  count.should == nr_matches
end

Then(/^the output should be (#{COUNT}) lines long$/) do |nr|
  all_output.split("\n").size.should == nr
end

Then(/^the output should contain a time$/) do
  time_rx = '(20\d{2})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) (\+\d+)?'
  # STDERR.puts "all_output '#{all_stdout}'"
  #sleep(1)
  assert_matching_output(time_rx, all_stdout)
end
