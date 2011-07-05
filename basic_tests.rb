require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/utils'
require 'test/unit'

#----------------------------------------------------------------

class BasicTests < Test::Unit::TestCase
  include Utils

  def setup()
    config = Config.get_config
    @metadata_dev = config[:metadata_dev]
    @data_dev = config[:data_dev]

    @data_block_size = 128
    @low_water = 1024
    @dm = DMInterface.new
  end

  def teardown()
  end

  def test_overwrite_a_linear_device
    linear_table = Table.new(Linear.new(2097152, @data_dev, 0))
    @dm.with_dev(linear_table) do |linear_dev|
      wipe_device(linear_dev)
    end
  end

  def test_overwriting_various_thin_devices
    info "Creating pool with new metadata"
    info "Zeroing metadata"
    wipe_device(@metadata_dev)

    pool_table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                        @data_block_size, @low_water))
    @dm.with_dev(pool_table) do |pool|

      pool.message(0, "new-thin 0")
      thin_table = Table.new(Thin.new(2097152, pool, 0))
      @dm.with_dev(thin_table) do |thin|
        info "Benchmarking an unprovisioned thin device"
        wipe_device(thin)
        
        info "Benchmarking a fully provisioned thin device"
        wipe_device(thin)
      end

      pool.message(0, "new-snap 1 0")
      @dm.with_dev(Table.new(Thin.new(2097152, pool, 1))) do |snap|
        info "Benchmarking a snapshot of a fully provisioned device"
        wipe_device(snap)
      
        info "Benchmarking a snapshot with no sharing"
        wipe_device(snap)
      end
    end
  end
end

#----------------------------------------------------------------
