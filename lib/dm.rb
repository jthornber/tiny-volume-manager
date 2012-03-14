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

  def initialize(sector_count, metadata_dev, data_dev, block_size, low_water_mark, zero = true, discard = true, discard_pass = true)
    extra_opts = Array.new

    extra_opts.instance_eval do
      push :skip_block_zeroing unless zero
      push :ignore_discard unless discard
      push :no_discard_passdown unless discard_pass
    end

    super('thin-pool', sector_count, metadata_dev, data_dev, block_size, low_water_mark, extra_opts.length, *extra_opts)
    @metadata_dev = metadata_dev
  end

  def post_remove_check
    ProcessControl.run("thin_check #{@metadata_dev}")
  end
end

class Thin < Target
  def initialize(sector_count, pool, id, origin = nil)
    if origin
      super('thin', sector_count, pool.path, id, origin)
    else
      super('thin', sector_count, pool.path, id)
    end
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

  def to_embed_
    start_sector = 0

    @targets.map do |t|
      r = "#{start_sector} #{start_sector + t.sector_count} #{t.type} #{t.args.join(' ')}"
      start_sector += t.sector_count
      r
    end.join("; ")
  end

  def to_embed
    "<<table:#{to_embed_}>>"
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
    Utils::with_temp_file('dm-table') do |f|
      debug "writing table: #{table.to_embed}"
      f.puts table.to_s
      f.flush
      ProcessControl.run("dmsetup load #{@name} #{f.path}")
    end

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
    Utils.retry_if_fails(5.0) do
      if File.exists?("/dev/mapper/" + @name)
        ProcessControl.run("dmsetup remove #{@name}")
      end
    end
  end

  def message(sector, *args)
    ProcessControl.run("dmsetup message #{path} #{sector} #{args.join(' ')}")
  end

  def status
    ProcessControl.run("dmsetup status #{@name}")
  end

  def info
    ProcessControl.run("dmsetup info #{@name}")
  end

  def event_nr
    output = ProcessControl.run("dmsetup status -v #{@name}")
    m = output.match(/Event number:[ \t]*([0-9]+)/)
    if m.nil?
      raise RuntimeError, "Couldn't find event number for dm device"
    end

    m[1].to_i
  end

  def event_tracker(&condition)
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

  # discards bytes delimited by b (begin, inclusive) and e (end,
  # non-inclusive).  b and e are given in 512 byte sectors.
  BLKDISCARD = 4727

  def discard(b, e)
    File.open(path, File::RDWR | File::NONBLOCK) do |ctrl|
      ctrl.ioctl(BLKDISCARD, [b * 512, e * 512].pack('QQ'))
    end
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
  def wait(&condition)
    until condition.call
      ProcessControl.run("dmsetup wait #{@device.name} #{@event_nr}")
      @event_nr = @device.event_nr
    end
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
