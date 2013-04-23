When(/^I tvm (.*)$/) do |cmd|
  in_current_dir do
    metadata.persist
  end

  run_simple(unescape("tvm #{cmd}"), false)

  in_current_dir do
    reload_metadata
  end
end


Then(/^"(.*?)" should have size (\d+\w+)$/) do |name, size|
  size = DiskUnits::DiskSize.parse(size)
  in_current_dir do
    vm.volume_by_name(name).size.should == size
  end
end

Given(/^"(.*?)" has size (\d+\w+)/) do |name, size|
  size = DiskUnits::DiskSize.parse(size)
  in_current_dir do
    vol = vm.volume_by_name(name)
    vm.resize(vol, size)
  end
end
