require 'rspec/core/rake_task'
require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["--color"]
end

ssh_user = "ejt@device-mapper.com"
ssh_port = "22"
document_root = "~/www/testing"
rsync_delete = true
rsync_args = ""
public_dir = "reports"

desc "Deploy reports via rsync"
task :deploy do
  exclude = ""
  if File.exists?('./rsync-exclude')
    exclude = "--exclude-from '#{File.expand_path('./rsync-exclude')}'"
  end

  puts "## Deploying reports via Rsync"
  ok_failed system("rsync -avze 'ssh -p #{ssh_port}' #{exclude} #{rsync_args} #{"--delete" unless rsync_delete == false} #{public_dir} #{ssh_user}:#{document_root}")
end

def ok_failed(condition)
  if (condition)
    puts "OK"
  else
    puts "FAILED"
  end
end
