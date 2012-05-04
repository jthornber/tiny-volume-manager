require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class CreationTests < ThinpTestCase
  include Tags
  include TinyVolumeManager
  include Utils

  def setup
    super
    @max=1000
  end

  tag :thinp_target, :create_lots

  def test_create_lots_of_empty_thins
    with_standard_pool(@size) do |pool|
      0.upto(@max) {|id| pool.message(0, "create_thin #{id}")}
    end
  end

  def test_create_lots_of_snaps
    with_standard_pool(@size) do |pool|
      pool.message(0, "create_thin 0")
      1.upto(@max) {|id| pool.message(0, "create_snap #{id} 0")}
    end
  end

  def test_create_lots_of_recursive_snaps
    with_standard_pool(@size) do |pool|
      pool.message(0, "create_thin 0")
      1.upto(@max) {|id| pool.message(0, "create_snap #{id} #{id - 1}")}
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
      with_new_thin(pool, volume_size, 0) {|thin| dt_device(thin)}
    end
  end

  tag :thinp_target, :quick

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
    @dm.with_dev(table) {|pool| {}}
  end

  def test_too_large_a_dev_t_fails
    with_standard_pool(@size) do |pool|
      assert_raises(ExitError) {pool.message(0, "create_thin #{2**24}")}
    end
  end

  def test_largest_dev_t_succeeds
    with_standard_pool(@size) {|pool| pool.message(0, "create_thin #{2**24 - 1}")}
  end

  def test_too_small_a_metadata_dev_fails
    tvm = VM.new
    tvm.add_allocation_volume(@data_dev, 0, dev_size(@data_dev))

    md_size = 32                # 16k, way too small
    data_size = 2097152
    tvm.add_volume(linear_vol('metadata', md_size))
    tvm.add_volume(linear_vol('data', 2097152))

    with_devs(tvm.table('metadata'),
              tvm.table('data')) do |md, data|
      wipe_device(md)
      assert_raise(ExitError) do
        with_dev(Table.new(ThinPool.new(data_size, md, data, 128, 1))) do |pool|
          # shouldn't get here
        end
      end
    end
  end

  def test_remove_of_a_pool_on_a_suspended_metadata_dev_works
    tvm = VM.new
    tvm.add_allocation_volume(@data_dev, 0, dev_size(@data_dev))

    data_size = 2097152
    tvm.add_volume(linear_vol('metadata', 4096))
    tvm.add_volume(linear_vol('data', data_size))

    with_devs(tvm.table('metadata'),
              tvm.table('data')) do |md, data|
      wipe_device(md)

      with_dev(Table.new(ThinPool.new(data_size, md, data, 128, 1))) do |pool|
        with_new_thin(pool, @volume_size / 4, 0) {|thin| wipe_device(thin)}
        STDERR.puts "wiped thin"
        sleep(5)
        md.suspend
        STDERR.puts "suspended metadata dev"
      end
      STDERR.puts "removed pool"
      md.resume
    end
  end
end

#----------------------------------------------------------------
