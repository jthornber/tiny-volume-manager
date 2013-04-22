Then(/^"(.*?)" should have size (\d+\w+)$/) do |name, size|
  size = DiskUnits::DiskSize.parse(size)
  in_current_dir do
    reload_metadata             # FIXME: we should automatically save/reload whenever an external process is run
    vm.volume_by_name(name).size.should == size
  end
end

Given(/^"(.*?)" has size (\d+\w+)/) do |name, size|
  size = DiskUnits::DiskSize.parse(size)
  in_current_dir do
    vol = vm.volume_by_name(name)
    vm.resize(vol, size)
    metadata.persist
  end
end
