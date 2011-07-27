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

    wipe_device(@metadata_dev, 8)
  end

  def teardown
  end

  # fixme: use Struct?
  class PoolStatus
    attr_reader :transaction_id, :free_data_sectors, :free_metadata_sectors, :held_root

    def initialize(t, d, m, h)
      @transaction_id = t
      @free_data_sectors = d
      @free_metadata_sectors = m
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

  def test_create_delete_cycle
    size = 2097152

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      10.times do
        pool.message(0, "create_thin 0")
        pool.message(0, "delete 0")
      end
    end
  end

  def test_delete_thin
    size = 2097152

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|

      # totally provision a thin device
      pool.message(0, 'create_thin 0')
      @dm.with_dev(Table.new(Thin.new(size, pool, 0))) do |thin|
        wipe_device(thin)
      end

      status = pool_status(pool)
      assert_equal(0, status.free_data_sectors)

      pool.message(0, 'delete 0')
      status = pool_status(pool)
      assert_equal(size, status.free_data_sectors)
    end
  end

  def test_delete_unknown_devices
    size = 2097152

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      0.upto(10) do |i|
        assert_raises(RuntimeError) do
          pool.message(0, "delete #{i}")
        end
      end
    end
  end
end

#----------------------------------------------------------------
