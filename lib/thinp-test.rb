require 'lib/bufio'
require 'lib/log'
require 'test/unit'

#----------------------------------------------------------------

class ThinpTestCase < Test::Unit::TestCase
  undef_method :default_test

  def setup
    config = Config.get_config
    @metadata_dev = config[:metadata_dev]
    @data_dev = config[:data_dev]

    @data_block_size = 128
    @low_water = 1024
    @dm = DMInterface.new

    wipe_device(@metadata_dev, 8)

    @bufio = BufioParameters.new
    @bufio.set_param('peak_allocated', 0)
  end

  def teardown
    info("Peak bufio allocation was #{@bufio.get_param('peak_allocated')}")
  end

  def with_standard_pool(size)
    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      yield(pool)
    end
  end

  def with_thin(pool, size, id)
    @dm.with_dev(Table.new(Thin.new(size, pool, id))) do |thin|
      yield(thin)
    end
  end

  def with_new_thin(pool, size, id, &block)
    pool.message(0, "create_thin #{id}")
    with_thin(pool, size, id, &block)
  end

  def with_new_snap(pool, size, id, origin, thin = nil, &block)
    if thin.nil?
        pool.message(0, "create_snap #{id} #{origin}")
        with_thin(pool, size, id, &block)
    else
      thin.pause do
        pool.message(0, "create_snap #{id} #{origin}")
        with_thin(pool, size, id, &block)
      end
    end
  end

  def assert_bad_table(table)
    assert_raises(RuntimeError) do
      @dm.with_dev(table) do |pool|
      end
    end
  end
end

#----------------------------------------------------------------
