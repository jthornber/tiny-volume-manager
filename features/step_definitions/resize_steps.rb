Then(/^"(.*?)" should have size (\d+\w+)$/) do |name, size|
  size = DiskUnits::DiskSize.parse(size)
  vm.volume_by_name(name).size.should == size
end
