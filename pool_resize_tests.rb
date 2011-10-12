require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class PoolResizeTests < ThinpTestCase
  include Tags
  include Utils

  def setup
    super
    @low_water_mark = 0 if @low_water_mark.nil?
    @data_block_size = 128
  end

  tag :thinp_target

  def test_reload_no_io
    table = Table.new(ThinPool.new(@size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water_mark))

    @dm.with_dev(table) do |pool|
      pool.load(table)
      pool.resume
    end
  end

  def test_reload_io
    table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water_mark))

    @dm.with_dev(table) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        fork {wipe_device(thin)}
        ProcessControl.sleep 5
        pool.load(table)
        pool.resume
        Process.wait
      end
    end
  end

  def test_resize_no_io
    target_step = @size / 10
    with_standard_pool(target_step) do |pool|
      2.upto(10) do |n|
        table = Table.new(ThinPool.new(n * target_step, @metadata_dev, @data_dev,
                                       @data_block_size, @low_water_mark))
        pool.load(table)
        pool.resume
      end
    end
  end

  def resize_io_many(n)
    target_step = div_up(@volume_size / n, @data_block_size)
    with_standard_pool(target_step) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        event_tracker = pool.event_tracker;

        fork {wipe_device(thin)}

        2.upto(n) do |i|
          # wait until available space has been used
          event_tracker.wait do
            status = PoolStatus.new(pool)
            status.free_data_sectors <= @low_water_mark * @data_block_size
          end

          table = Table.new(ThinPool.new(i * target_step, @metadata_dev, @data_dev,
                                         @data_block_size, @low_water_mark))
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

  # def test_reload_an_empty_table
  #   with_standard_pool(@size) do |pool|
  #     with_new_thin(pool, @volume_size, 0) do |thin|
  #       fork {wipe_device(thin)}

  #       sleep 5
  #       empty = Table.new
  #       pool.load(empty)
  #       pool.resume
  #     end
  #   end
  # end
end

#----------------------------------------------------------------
