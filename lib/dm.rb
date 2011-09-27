require 'lib/log'
require 'lib/process'
require 'lib/utils'

#----------------------------------------------------------------

class Target
  attr_accessor :type, :args, :sector_count

  def initialize(t, sector_count, *args)
    @type = t
    @sector_count = sector_count
    @args = args
  end
end

class Linear < Target
  def initialize(sector_count, dev, offset)
    super('linear', sector_count, dev, offset)
  end
end

class ThinPool < Target
  attr_accessor :metadata_dev
  def initialize(sector_count, metadata_dev, data_dev, block_size, low_water_mark, zero = true)
    if zero
      super('thin-pool', sector_count, metadata_dev, data_dev, block_size, low_water_mark)
    else
      super('thin-pool', sector_count, metadata_dev, data_dev, block_size, low_water_mark, 1, 'skip_block_zeroing')
    end

    @metadata_dev = metadata_dev
  end

  def post_remove_check
    ProcessControl.run("thin_repair #{@metadata_dev}")
  end
end

class Thin < Target
  def initialize(sector_count, pool, id)
    super('thin', sector_count, pool.path, id)
  end
end

#----------------------------------------------------------------

class Table
  attr_accessor :targets

  def initialize(*targets)
    @targets = targets
  end

  def to_s()
    start_sector = 0

    @targets.map do |t|
      r = "#{start_sector} #{start_sector + t.sector_count} #{t.type} #{t.args.join(' ')}"
      start_sector += t.sector_count
      r
    end.join("\n")    
  end
end

class DMDev
  attr_accessor :name
  attr_reader :interface, :active_table
  
  def initialize(name, interface)
    @name = name
    @interface = interface
  end

  def path()
    "/dev/mapper/#{name}"
  end

  def load(table)
    # fixme: better to use popen and pump the table in on stdin
    ProcessControl.run("dmsetup load #{@name} --table \"#{table}\"")
    @active_table = table
  end

  def suspend
    ProcessControl.run("dmsetup suspend #{@name}")
  end

  def pause(&block)
    suspend
    bracket_(method(:resume), &block)
  end

  def resume()
    ProcessControl.run("dmsetup resume #{@name}")
  end

  def remove()
    Utils.retry_if_fails(1.0) do
      ProcessControl.run("dmsetup remove #{@name}")
    end
  end

  def message(sector, *args)
    ProcessControl.run("dmsetup message #{path} #{sector} #{args.join(' ')}")
  end

  def status
    ProcessControl.run("dmsetup status #{@name}")
  end

  def event_nr
    output = ProcessControl.run("dmsetup status -v #{@name}")
    m = output.match(/Event number:[ \t]*([0-9]+)/)
    if m.nil?
      raise RuntimeError, "Couldn't find event number for dm device"
    end

    m[1].to_i
  end

  def event_tracker
    DMEventTracker.new(event_nr, self)
  end

  def post_remove_check
    @active_table.targets.each do |target|
      if target.public_methods.member?('post_remove_check')
        target.post_remove_check
      end
    end
  end

  def to_s()
    path
  end
end

class DMEventTracker
  attr_reader :event_nr, :device

  def initialize(n, d)
    @event_nr = n
    @device = d
  end

  # Wait for an event _since_ this one.  Updates event nr to reflect
  # the new number.
  def wait
    ProcessControl.run("dmsetup wait #{@device.name} #{@event_nr}")
    @event_nr = @device.event_nr
  end
end

class DMInterface
  def with_dev(table = nil, &block)
    bracket(create(table),
            lambda {|dev| dev.remove; dev.post_remove_check},
            &block)
  end

  def with_devs(*tables, &block)
    release = lambda do |devs|
      devs.each do |dev|
        begin
          dev.remove
          dev.post_remove_check
        rescue
        end
      end
    end

    bracket(Array.new, release) do |devs|
      tables.each do |table|
        devs << create(table)
      end

      block.call(*devs)
    end
  end

  def mk_dev(table = nil)
    create(table)
  end

private
  def create(table = nil)
    name = create_name
    ProcessControl.run("dmsetup create #{name} --notable")
    protect_(lambda {ProcessControl.run("dmsetup remove #{name}")}) do
      dev = DMDev.new(name, self)
      unless table.nil?
        dev.load table
        dev.resume
      end
      dev
    end
  end

  def create_name()
    # fixme: check this device doesn't already exist
    "test-dev-#{rand(1000000)}"
  end
end

#----------------------------------------------------------------
