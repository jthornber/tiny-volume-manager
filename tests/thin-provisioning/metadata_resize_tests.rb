require 'config'
require 'lib/device_mapper'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/status'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/disk-units'

require 'pp'

#----------------------------------------------------------------

class MetadataResizeTests < ThinpTestCase
  include DiskUnits
  include Tags
  include Utils
  include TinyVolumeManager

  def setup
    super
    @low_water_mark = 0 if @low_water_mark.nil?
    @data_block_size = 128

    @tvm = VM.new
    @tvm.add_allocation_volume(@data_dev, 0, dev_size(@data_dev))
  end

  tag :thinp_target

  def test_resize_metadata_no_io
    data_size = meg(100)
    @tvm.add_volume(linear_vol('metadata', meg(1)))
    @tvm.add_volume(linear_vol('data', data_size))

    with_devs(@tvm.table('metadata'),
              @tvm.table('data')) do |md, data|
      wipe_device(md, 8)

      table = Table.new(ThinPoolTarget.new(data_size, md, data, @data_block_size, @low_water_mark))
      with_dev(table) do |pool|
        status1 = PoolStatus.new(pool)

        @tvm.resize('metadata', meg(2))
        pool.pause do
          md.pause do
            table = @tvm.table('metadata')
            md.load(table)
          end
        end

        status2 = PoolStatus.new(pool)

        assert_equal(status1.total_metadata_blocks * 2, status2.total_metadata_blocks)
      end
    end
  end

  def test_resize_metadata_with_io
    data_size = gig(1)
    @tvm.add_volume(linear_vol('metadata', meg(1)))
    @tvm.add_volume(linear_vol('data', data_size))

    with_devs(@tvm.table('metadata'),
              @tvm.table('data')) do |md, data|
      wipe_device(md, 8)

      table = Table.new(ThinPoolTarget.new(data_size, md, data, @data_block_size, @low_water_mark))
      with_dev(table) do |pool|
        status1 = PoolStatus.new(pool)

        with_new_thin(pool, meg(50), 0) do |thin|
          fork {wipe_device(thin)}
          ProcessControl.sleep 5

          @tvm.resize('metadata', meg(2))
          pool.pause do
            md.pause do
              table = @tvm.table('metadata')
              md.load(table)
            end
          end

          Process.wait
        end

        status2 = PoolStatus.new(pool)

        assert_equal(status1.total_metadata_blocks * 2, status2.total_metadata_blocks)
      end
    end
  end

  def _test_exhausting_metadata_space_causes_fail_mode
    md_blocks = 8
    md_size = 10 * md_blocks
    data_size = gig(2)

    @tvm.add_volume(linear_vol('metadata', md_size))
    @tvm.add_volume(linear_vol('data', data_size))

    with_devs(@tvm.table('metadata'),
              @tvm.table('data')) do |md, data|
      wipe_device(md, 8)

      table = Table.new(ThinPoolTarget.new(data_size, md, data, @data_block_size, @low_water_mark))
      with_dev(table) do |pool|
        with_new_thin(pool, @volume_size, 0) do |thin|
          wipe_device(thin)
        end

        pp PoolStatus.new(pool)
      end
    end
  end

  # It's hard to predict how much metadata will be used by a
  # particular operation.  So the approach we'll take is to set up a
  # pool, do some work, query to see how much is used and then set the
  # thresholds appropriately.

  def _test_low_metadata_space_triggers_event
    md_blocks = 8
    md_size = 128 * md_blocks
    data_size = gig(2)

    @tvm.add_volume(linear_vol('metadata', md_size))
    @tvm.add_volume(linear_vol('data', data_size))

    with_devs(@tvm.table('metadata'),
              @tvm.table('data')) do |md, data|
      wipe_device(md, 8)

      table = Table.new(ThinPoolTarget.new(data_size, md, data, @data_block_size, @low_water_mark))
      with_dev(table) do |pool|
        with_new_thin(pool, @volume_size, 0) do |thin|
          # We want to do just enough io to take the metadata dev over
          # the threshold, _without_ running out of space.
          wipe_device(thin, 1024)
        end

        pp PoolStatus.new(pool)
      end
    end
  end
 end

#----------------------------------------------------------------
