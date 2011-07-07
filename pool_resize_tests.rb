require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'test/unit'

#----------------------------------------------------------------

class PoolResizeTests < Test::Unit::TestCase
  include Utils

  def setup
    config = Config.get_config
    @metadata_dev = config[:metadata_dev]
    @data_dev = config[:data_dev]

    @data_block_size = 128
    @low_water = 1024
    @dm = DMInterface.new

    wipe_device(@metadata_dev)
  end

  def teardown
  end

  def test_reload_no_io
    table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      pool.load(table)
      pool.resume
    end
  end

  def test_reload_io
    table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      pool.message(0, 'new-thin 0')
      @dm.with_dev(Table.new(Thin.new(2097152, pool, 0))) do |thin|
        fork {wipe_device(thin)}
        ProcessControl.sleep 10
        pool.load(table)
        pool.resume
        Process.wait
      end
    end
  end

  def test_resize_no_io
    target_size = 20971520
    target_step = target_size / 10
    table_small = Table.new(ThinPool.new(target_step, @metadata_dev, @data_dev,
                                         @data_block_size, @low_water))

    @dm.with_dev(table_small) do |pool|
      2.upto(10) do |n|
        table = Table.new(ThinPool.new(n * target_step, @metadata_dev, @data_dev,
                                       @data_block_size, @low_water))

        pool.load(table)
        pool.resume
      end
    end
  end

  def resize_io_many(n)
    target_size = 2097152
    target_step = target_size / n
    table_small = Table.new(ThinPool.new(target_step, @metadata_dev, @data_dev,
                                         @data_block_size, @low_water))

    @dm.with_dev(table_small) do |pool|
      pool.message(0, 'new-thin 0')

      @dm.with_dev(Table.new(Thin.new(2097152, pool, 0))) do |thin|
        event_tracker = pool.event_tracker;

        fork {wipe_device(thin)}

        2.upto(n) do |i|
          # wait until available space has been used
          event_tracker.wait

          table = Table.new(ThinPool.new(i * target_step, @metadata_dev, @data_dev,
                                         @data_block_size, @low_water))
          pool.load(table)
          pool.resume
        end

        Process.wait
        if $?.exitstatus > 0
          raise RuntimeError, "wipe sub process failed"
        end
      end
    end
  end

  def test_resize_io
    resize_io_many(8)
  end
end

#----------------------------------------------------------------
