require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'test/unit'

#----------------------------------------------------------------

class DeletionTests < Test::Unit::TestCase
  include Utils

  def setup
    config = Config.get_config
    @metadata_dev = config[:metadata_dev]
    @data_dev = config[:data_dev]

    @data_block_size = 128
    @low_water = 1024
    @dm = DMInterface.new
    @size = 2097152

    wipe_device(@metadata_dev, 8)
  end

  def teardown
  end

  # FIXME: move into lib
  # fixme: use Struct?
  class PoolStatus
    attr_reader :transaction_id, :free_metadata_sectors, :free_data_sectors, :held_root

    def initialize(t, m, d, h)
      @transaction_id = t
      @free_metadata_sectors = m
      @free_data_sectors = d
      @held_root = h
    end
  end

  def pool_status(p)
    status = p.status
    m = status.match(/(\d+)\s(\d+)\s(\d+)\s(\S+)/)
    if m.nil?
      raise RuntimeError, "couldn't get pool status"
    end

    PoolStatus.new(m[1].to_i, m[2].to_i, m[3].to_i, m[4])
  end

  def with_standard_pool
    table = Table.new(ThinPool.new(@size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      yield(pool)
    end
  end

  def with_new_thin(id)
    pool.message(0, "create_thin #{id}")
      @dm.with_dev(Table.new(Thin.new(@size, pool, id))) do |thin|
      yield(thin)
    end
  end

  def test_create_delete_cycle
    with_standard_pool do |pool|
      10.times do
        pool.message(0, "create_thin 0")
        pool.message(0, "delete 0")
      end
    end
  end

  def test_delete_thin
    with_standard_pool do |pool|
      # totally provision a thin device
      with_new_thin(0) do |thin|
        wipe_device(thin)
      end

      status = pool_status(pool)
      assert_equal(0, status.free_data_sectors)

      pool.message(0, 'delete 0')
      status = pool_status(pool)
      assert_equal(@size, status.free_data_sectors)
    end
  end

  def test_delete_unknown_devices
    with_standard_pool do |pool|
      0.upto(10) do |i|
        assert_raises(RuntimeError) do
          pool.message(0, "delete #{i}")
        end
      end
    end
  end

  def test_delete_active_device_fails
    with_standard_pool do |pool|
      with_new_thin(0) do |thin|
        fork {dt_device(thin)}
        ProcessControl.sleep(5)

        assert_raises(RuntimeError) do
          pool.message(0, 'delete 0')
        end

        Process.wait
      end
    end
  end
end

#----------------------------------------------------------------
