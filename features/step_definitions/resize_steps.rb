Then(/^"(.*?)" should have size (\d+\w+)$/) do |name, size|
  size = DiskUnits::DiskSize.parse(size)
  in_current_dir do
    reload_metadata
    vm.volume_by_name(name).size.should == size
  end
end
