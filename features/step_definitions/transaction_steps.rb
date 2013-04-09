Given(/^pending transaction$/) do
  in_current_dir do
    vm.begin
    metadata.save_metadata
  end
end
