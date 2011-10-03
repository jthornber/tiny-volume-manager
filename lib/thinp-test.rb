require 'lib/bufio'
require 'lib/log'
require 'test/unit'

#----------------------------------------------------------------

$checked_prerequisites = false

class ThinpTestCase < Test::Unit::TestCase
  undef_method :default_test

  def setup
    check_prereqs()

    config = Config.get_config
    @metadata_dev = config[:metadata_dev]
    @data_dev = config[:data_dev]

    @size = config[:data_size]
    @size = 20971520 if @size.nil?

    @volume_size = config[:volume_size]
    @volume_size = 2097152 if @volume_size.nil?

    @data_block_size = config[:data_block_size]
    @data_block_size = 128 if @data_block_size.nil?

    @tiny_size = @data_block_size

    @low_water_mark = config[:low_water_mark]
    @low_water_mark = 1024 if @low_water_mark.nil?

    @dm = DMInterface.new

    wipe_device(@metadata_dev, 8)

    @bufio = BufIOParams.new
    @bufio.set_param('peak_allocated_bytes', 0)
  end

  def teardown
    info("Peak bufio allocation was #{@bufio.get_param('peak_allocated_bytes')}")
  end

  def with_standard_pool(size)
    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water_mark))

    @dm.with_dev(table) do |pool|
      yield(pool)
    end
  end

  def with_dev(table, &block)
    @dm.with_dev(table, &block)
  end

  def with_devs(*tables, &block)
    @dm.with_devs(*tables, &block)
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

  def with_thins(pool, size, *ids, &block)
    tables = ids.map {|id| Table.new(Thin.new(size, pool, id))}
    @dm.with_devs(*tables, &block)
  end

  def with_new_snap(pool, size, id, origin, thin = nil, &block)
    if thin.nil?
        pool.message(0, "create_snap #{id} #{origin}")
        with_thin(pool, size, id, &block)
    else
      thin.pause do
        pool.message(0, "create_snap #{id} #{origin}")
      end
      with_thin(pool, size, id, &block)
    end
  end

  def in_parallel(*ary, &block)
    threads = Array.new
    ary.each do |entry|
      threads << Thread.new(entry) do |e|
        block.call(e)
      end
    end

    threads.each {|t| t.join}
  end

  def assert_bad_table(table)
    assert_raises(RuntimeError) do
      @dm.with_dev(table) do |pool|
      end
    end
  end

  private
  def check_prereqs
    return if $checked_prerequisites

    # Can we find thin_repair?
    begin
      raise "wrong ruby version" unless RUBY_VERSION =~ /^1.8/
      ProcessControl.run('which thin_repair')
      ProcessControl.run('which dt')
    rescue
      STDERR.puts "Missing prerequisites, please check the README"
      exit(1)
    end

    $checked_prerequisites = true
  end
end

#----------------------------------------------------------------
