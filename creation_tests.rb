require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'test/unit'

#----------------------------------------------------------------

class CreationTests < Test::Unit::TestCase
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

  def test_create_lots_of_empty_thins
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      0.upto(1000) {|i| pool.message(0, "create_thin #{i}") }
    end
  end

  def test_create_lots_of_snaps
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      pool.message(0, "create_thin 0")
      1.upto(1000) {|i| pool.message(0, "create_snap #{i} 0") }
    end
  end

  def test_create_lots_of_recursive_snaps
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      pool.message(0, "create_thin 0")
      1.upto(1000) {|i| pool.message(0, "create_snap #{i} #{i - 1}") }
    end
  end

  def test_non_power_of_2_data_block_size_fails
    size = 20971520
    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size + 57, @low_water))

    assert_raises(RuntimeError) do
      @dm.with_dev(table) do |pool|
        # shouldn't get here
      end
    end
  end

  def test_too_small_data_block_size_fails
    size = 20971520
    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   64, @low_water))

    assert_raises(RuntimeError) do
      @dm.with_dev(table) do |pool|
        # shouldn't get here
      end
    end
  end

  def test_too_large_data_block_size_fails
    size = 20971520
    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   2**21, @low_water))

    assert_raises(RuntimeError) do
      @dm.with_dev(table) do |pool|
        # shouldn't get here
      end
    end
  end

  def test_largest_data_block_size_succeeds
    size = 20971520
    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   2**21 - 1, @low_water))
    @dm.with_dev(table) do |pool|
    end
  end

  def test_too_large_a_dev_t_fails
    size = 20971520
    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))
    assert_raises(RuntimeError) do
      @dm.with_dev(table) do |pool|
        pool.message("create_thin #{2**24}")
      end
    end
  end

  def test_too_large_a_dev_t_fails
    size = 20971520
    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))
    @dm.with_dev(table) do |pool|
      pool.message("create_thin #{2**24 - 1}")
    end
  end
end

#----------------------------------------------------------------
