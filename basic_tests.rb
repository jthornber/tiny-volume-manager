require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/thinp-test'

#----------------------------------------------------------------

class BasicTests < ThinpTestCase
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
      dt_device(linear_dev)
    end
  end

  def test_overwriting_various_thin_devices
    info "Creating pool with new metadata"
    info "Zeroing metadata"
    wipe_device(@metadata_dev, 8)

    # we keep tearing down the pool and setting it back up so that we
    # can trigger a thin_repair check at each stage.

    info "Benchmarking an unprovisioned thin device"
    pool_table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                        @data_block_size, @low_water))
    @dm.with_dev(pool_table) do |pool|

      pool.message(0, "create_thin 0")
      thin_table = Table.new(Thin.new(2097152, pool, 0))
      @dm.with_dev(thin_table) do |thin|
        dt_device(thin)
      end
    end

    info "Benchmarking a fully provisioned thin device"
    pool_table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                        @data_block_size, @low_water))
    @dm.with_dev(pool_table) do |pool|
      thin_table = Table.new(Thin.new(2097152, pool, 0))
      @dm.with_dev(thin_table) do |thin|
        dt_device(thin)
      end
    end

    info "Benchmarking a snapshot of a fully provisioned device"
    pool_table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                        @data_block_size, @low_water))
    @dm.with_dev(pool_table) do |pool|
      pool.message(0, "create_snap 1 0")
      @dm.with_dev(Table.new(Thin.new(2097152, pool, 1))) do |snap|
        dt_device(snap)
      end
    end

    info "Benchmarking a snapshot with no sharing"
    pool_table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                        @data_block_size, @low_water))
    @dm.with_dev(pool_table) do |pool|
      @dm.with_dev(Table.new(Thin.new(2097152, pool, 1))) do |snap|
        dt_device(snap)
      end
    end
  end

  def test_ext4_weirdness
    info "Creating pool with new metadata"
    info "Zeroing metadata"
    wipe_device(@metadata_dev, 8)

    pool_table = Table.new(ThinPool.new(20971520, @metadata_dev, @data_dev,
                                        @data_block_size, @low_water))
    @dm.with_dev(pool_table) do |pool|

      pool.message(0, "create_thin 0")
      thin_table = Table.new(Thin.new(2097152, pool, 0))
      @dm.with_dev(thin_table) do |thin|
        thin_fs = FS::file_system(:ext4, thin)
        thin_fs.format

        thin.suspend
        pool.message(0, "create_snap 1 0")
        thin.resume

        dt_device(thin)
      end
    end
  end
end

#----------------------------------------------------------------
