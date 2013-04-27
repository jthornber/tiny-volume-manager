require 'lib/command_line'

#----------------------------------------------------------------

module TVM
  module Detail
    TVMCommandLine = CommandLine::Parser.new do
      value_type :string do |str|
        str
      end

      value_type :int do |str|
        str.to_i
      end

      value_type :disk_size do |str|
        DiskUnits::DiskSize.parse(str)
      end

      simple_switch :help, '--help', '-h'

      value_switch :type, :string, '--type'
      value_switch :alloc_volume, :string, '--alloc-volume'

      value_switch :size, :disk_size, '--size'
      value_switch :grow_to, :disk_size, '--grow-to'
      value_switch :grow_by, :disk_size, '--grow-by'
      value_switch :shrink_to, :disk_size, '--shrink-to'
      value_switch :shrink_by, :disk_size, '--shrink-by'

      global do
        switches :help
      end

      command :create

      command :create_allocator do
        switches :type, :alloc_volume
      end

      command :snap
      command :list
      command :commit
      command :abort
      command :status
      command :resize do
        one_of :grow_to, :grow_by, :shrink_to, :shrink_by, :size
      end
    end
  end

  def parse_command_line(dispatcher, *args)
    Detail::TVMCommandLine.parse(dispatcher, *args)
  end
end

#----------------------------------------------------------------
