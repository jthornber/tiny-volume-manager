require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class MultiplePoolTests < ThinpTestCase
  include Tags
  include TinyVolumeManager
  include Utils

  def setup
    super

    @block_size = 128
  end

  tag :thinp_target, :quick

  def test_two_pools_pointing_to_the_same_metadata_fails
    assert_raises(RuntimeError) do
      with_standard_pool(@size) do |pool1|
        with_standard_pool(@size) do |pool2|
          # shouldn't get here
        end
      end
    end
  end

  tag :thinp_target, :slow

  def test_two_pools_can_create_thins
    # carve up the data device into two metadata volumes and two data
    # volumes.
    tvm = VM.new
    tvm.add_allocation_volume(@data_dev, 0, dev_size(@data_dev))

    md_size = limit_metadata_dev_size(tvm.free_space / 16)
    1.upto(2) {|id| tvm.add_volume(linear_vol("md_#{id}", md_size))}

    data_size = limit_data_dev_size(round_up(tvm.free_space / 8, @block_size))
    1.upto(2) {|id| tvm.add_volume(linear_vol("data_#{id}", data_size))}

    # Activate.  We need a component that automates this from a
    # description of the system.
    with_devs(tvm.table('md_1'),
              tvm.table('md_2'),
              tvm.table('data_1'),
              tvm.table('data_2')) do |md_1, md_2, data_1, data_2|

      # zero the metadata so we get a fresh pool
      wipe_device(md_1, 8)
      wipe_device(md_2, 8)

      with_devs(Table.new(ThinPool.new(data_size, md_1, data_1, @block_size, 1)),
                Table.new(ThinPool.new(data_size, md_2, data_2, @block_size, 1))) do |pool1, pool2|

        with_new_thin(pool1, data_size, 0) do |thin1|
          with_new_thin(pool2, data_size, 0) do |thin2|
            in_parallel(thin1, thin2) {|t| dt_device(t)}
          end
        end
      end
    end
  end

  def test_stacked_pools
    with_pool_volume(@data_dev, @volume_size) do |layer1, *ignored|
      with_pool_volume(layer1) do |layer2, *ignored|
        with_pool_volume(layer2) {|layer3, *ignored| dt_device(layer3)}
      end
    end
  end
end
