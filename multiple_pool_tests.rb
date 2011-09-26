require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/thinp-test'

#----------------------------------------------------------------

class MultiplePoolTests < ThinpTestCase
  include Utils

  def test_two_pools_pointing_to_the_same_metadata_fails
    assert_raises(RuntimeError) do
      with_standard_pool(@size) do |pool1|
        with_standard_pool(@size) do |pool2|
          # shouldn't get here
        end
      end
    end
  end

  def test_two_pools_can_create_thins
    # carve up the data device into two metadata volumes and two data
    # volumes.
    tvm = TinyVolumeManager.new
    tvm.add_allocation_volume(@data_dev, 0, dev_size(@data_dev))

    md_size = tvm.free_space / 16
    1.upto(2) do |i|
      tvm.add_volume(VolumeDescription.new("md_#{i}", md_size))
    end

    block_size = 128
    data_size = (tvm.free_space / 8) / block_size * block_size
    1.upto(2) do |i|
      tvm.add_volume(VolumeDescription.new("data_#{i}", data_size))
    end

    # Activate.  We need a component that automates this from a
    # description of the system.
    with_devs(tvm.table('md_1'),
              tvm.table('md_2'),
              tvm.table('data_1'),
              tvm.table('data_2')) do |md_1, md_2, data_1, data_2|

      # zero the metadata so we get a fresh pool
      wipe_device(md_1, 8)
      wipe_device(md_2, 8)

      with_devs(Table.new(ThinPool.new(data_size, md_1, data_1, 128, 0)),
                Table.new(ThinPool.new(data_size, md_2, data_2, 128, 0))) do |pool1, pool2|

        with_new_thin(pool1, data_size, 0) do |thin1|
          with_new_thin(pool2, data_size, 0) do |thin2|
            in_parallel(thin1, thin2) {|t| dt_device(t)}
          end
        end
      end
    end
  end
end
