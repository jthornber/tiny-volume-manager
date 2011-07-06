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

  def test_reload_same_table_no_io
    table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      pool.load(table)
      pool.resume
    end
  end

  def test_reload_same_table_io
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

  def test_resize_table_no_io
    target_size = 20971520
    target_step = target_size / 10
    table_small = Table.new(ThinPool.new(0, @metadata_dev, @data_dev,
                                         @data_block_size, @low_water))

    @dm.with_dev(table_small) do |pool|
      # we grow the table 10 times
      0.upto(9) do |n|
        table = Table.new(ThinPool.new(n * target_step, @metadata_dev, @data_dev,
                                       @data_block_size, @low_water))

        pool.load(table)
        pool.resume
      end
    end
  end

  def test_resize_table_io
    target_size = 2097152
    target_step = target_size / 8
    table_small = Table.new(ThinPool.new(0, @metadata_dev, @data_dev,
                                         @data_block_size, @low_water))

    @dm.with_dev(table_small) do |pool|
      pool.message(0, 'new-thin 0')
      @dm.with_dev(Table.new(Thin.new(2097152, pool, 0))) do |thin|
        fork {wipe_device(thin)}

        # we grow the table 10 times
        0.upto(7) do |n|
          table = Table.new(ThinPool.new(n * target_step, @metadata_dev, @data_dev,
                                         @data_block_size, @low_water))
          ProcessControl.sleep 5
          pool.load(table)
          pool.resume
        end

        Process.wait
      end
    end
  end
end

#----------------------------------------------------------------
