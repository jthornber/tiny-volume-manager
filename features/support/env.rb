ENV['RUBYLIB'] = "#{Dir.pwd}"
STDERR.puts "rubylib = #{ENV['RUBYLIB']}"

ENV['PATH'] = "#{Dir::pwd}:#{ENV['PATH']}"

require 'lib/tvm/tvm_api'
require 'features/support/transforms'
