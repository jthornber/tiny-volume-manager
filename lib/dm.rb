require 'lib/log'
require 'lib/process'

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
  def initialize(sector_count, metadata_dev, data_dev, block_size, low_water, zero = true)
    if zero
      super('thin-pool', sector_count, metadata_dev, data_dev, block_size, low_water)
    else
      super('thin-pool', sector_count, metadata_dev, data_dev, block_size, low_water, 1, 'skip_block_zeroing')
    end
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
  attr_reader :interface
  
  def initialize(name, interface)
    @name = name
    @interface = interface
  end

  def path()
    "/dev/mapper/#{name}"
  end

  def load(table)
    # fixme: better to use popen and pump the table in on stdin
    ProcessControl.run("dmsetup load #{name} --table \"#{table}\"")
  end

  def resume()
    ProcessControl.run("dmsetup resume #{name}")
  end

  def remove()
    ProcessControl.run("dmsetup remove #{name}")
  end

  def message(sector, *args)
    ProcessControl.run("dmsetup message #{path} #{sector} #{args.join(' ')}")
  end

  def to_s()
    path
  end
end

class DMInterface
  def with_dev(table = nil)
    dev = create(table)

    begin
      yield(dev)
    ensure
      dev.remove
    end
  end

private
  def create(table = nil)
    name = create_name()

    ProcessControl.run("dmsetup create #{name} --notable")
    dev = DMDev.new(name, self)
    unless table.nil?
      dev.load table
      dev.resume
    end

    dev
  end

  def create_name()
    # fixme: check this device doesn't already exist
    "test-dev-#{rand(1000000)}"
  end
end

#----------------------------------------------------------------
