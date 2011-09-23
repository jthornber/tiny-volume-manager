require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/thinp-test'

#----------------------------------------------------------------

class CreationTests < ThinpTestCase
  include Utils

  def test_create_lots_of_empty_thins
    with_standard_pool(@size) do |pool|
      0.upto(1000) {|i| pool.message(0, "create_thin #{i}") }
    end
  end

  def test_create_lots_of_snaps
    with_standard_pool(@size) do |pool|
      pool.message(0, "create_thin 0")
      1.upto(1000) {|i| pool.message(0, "create_snap #{i} 0") }
    end
  end

  def test_create_lots_of_recursive_snaps
    with_standard_pool(@size) do |pool|
      pool.message(0, "create_thin 0")
      1.upto(1000) {|i| pool.message(0, "create_snap #{i} #{i - 1}") }
    end
  end

  def test_non_power_of_2_data_block_size_fails
    table = Table.new(ThinPool.new(@size, @metadata_dev, @data_dev,
                                   @data_block_size + 57, @low_water_mark))
    assert_bad_table(table)
  end

  def test_too_small_data_block_size_fails
    table = Table.new(ThinPool.new(@size, @metadata_dev, @data_dev,
                                   64, @low_water_mark))
    assert_bad_table(table)
  end

  def test_too_large_data_block_size_fails
    table = Table.new(ThinPool.new(@size, @metadata_dev, @data_dev,
                                   2**21 + 1, @low_water_mark))
    assert_bad_table(table)
  end

  def test_largest_data_block_size_succeeds
    table = Table.new(ThinPool.new(@size, @metadata_dev, @data_dev,
                                   2**21, @low_water_mark))
    @dm.with_dev(table) do |pool|
    end
  end

  def test_too_large_a_dev_t_fails
    with_standard_pool(@size) do |pool|
      assert_raises(RuntimeError) do
        pool.message(0, "create_thin #{2**24}")
      end
    end
  end

  def test_largest_dev_t_succeeds
    with_standard_pool(@size) do |pool|
      pool.message(0, "create_thin #{2**24 - 1}")
    end
  end

  def test_huge_block_size
    size = @size
    data_block_size = 524288
    volume_size = 524288
    lwm = 5
    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   data_block_size, lwm))
    @dm.with_dev(table) do |pool|
      with_new_thin(pool, volume_size, 0) do |thin|
        dt_device(thin)
      end
    end
  end
end

#----------------------------------------------------------------
