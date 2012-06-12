require 'lib/benchmarking'
require 'lib/bufio'
require 'lib/log'
require 'lib/metadata-utils'
require 'lib/prerequisites-checker'
require 'lib/process'
require 'lib/tvm'
require 'lib/utils'

#----------------------------------------------------------------

$prereqs = Prerequisites.requirements do
  require_in_path('thin_check',
                  'thin_dump',
                  'thin_restore',
                  'dt',
                  'blktrace',
                  'bonnie++')
  require_ruby_version /^1.8/
end

module ThinpTestMixin
  include Benchmarking
  include MetadataUtils
  include ProcessControl
  include TinyVolumeManager

  def setup
    check_prereqs

    config = Config.get_config
    @metadata_dev = config[:metadata_dev]
    @data_dev = config[:data_dev]

    @data_block_size = config.fetch(:data_block_size, 128)

    @size = config.fetch(:data_size, 20971520)
    @size /= @data_block_size
    @size *= @data_block_size

    @volume_size = config.fetch(:volume_size, 2097152)

    @tiny_size = @data_block_size
    @low_water_mark = config.fetch(:low_water_mark, 5)
    @mass_fs_tests_parallel_runs = config.fetch(:mass_fs_tests_parallel_runs, 128)

    @dm = DMInterface.new

    @bufio = BufIOParams.new
    @bufio.set_param('peak_allocated_bytes', 0)

    wipe_device(@metadata_dev, 8)
  end

  def teardown
    info("Peak bufio allocation was #{@bufio.get_param('peak_allocated_bytes')}")
  end

  def limit_metadata_dev_size(size)
    max_size = 8355840
    size = max_size if size > max_size
    size
  end

  #--------------------------------

  # low level dm handling
  def with_dev(table, &block)
    @dm.with_dev(table, &block)
  end

  def with_devs(*tables, &block)
    @dm.with_devs(*tables, &block)
  end

  #--------------------------------

  # table generation

  def standard_pool_table(size, opts = Hash.new)
    zero = opts.fetch(:zero, true)
    discard = opts.fetch(:discard, true)
    discard_pass = opts.fetch(:discard_passdown, true)
    read_only = opts.fetch(:read_only, false)

    Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                           @data_block_size, @low_water_mark,
                           zero, discard, discard_pass, read_only))
  end

  def standard_linear_table
    Table.new(Linear.new(@size, @data_dev, 0))
  end

  def thin_table(pool, size, id, opts = Hash.new)
    Table.new(Thin.new(size, pool, id, opts[:origin]))
  end

  #--------------------------------

  def with_standard_pool(size, opts = Hash.new, &block)
    with_dev(standard_pool_table(size, opts), &block)
  end

  def with_standard_linear(&block)
    with_dev(standard_linear_table, &block)
  end

  def with_standard_cache(&block)
    # we set up a small linear device, made out of the metadata dev.
    # That is at most a 16th the size of the data dev.
    tvm = VM.new
    md_size = dev_size(@metadata_dev)
    tvm.add_allocation_volume(@metadata_dev, 0, md_size)
    
    tvm.add_volume(linear_vol('cache', [md_size, round_up(@size / 16, @data_block_size)].min))
    with_dev(tvm.table('cache')) do |cache|
      table = Table.new(Cache.new(dev_size(@data_dev), @data_dev, cache, @data_block_size))
      with_dev(table, &block)
    end
  end

  def with_thin(pool, size, id, opts = Hash.new, &block)
    @dm.with_dev(thin_table(pool, size, id, opts), &block)
  end

  def with_new_thin(pool, size, id, opts = Hash.new, &block)
    pool.message(0, "create_thin #{id}")
    with_thin(pool, size, id, opts, &block)
  end

  def with_thins(pool, size, *ids, &block)
    tables = ids.map {|id| thin_table(pool, size, id)}
    @dm.with_devs(*tables, &block)
  end

  def with_new_thins(pool, size, *ids, &block)
    ids.each do |id|
      pool.message(0, "create_thin #{id}")
    end

    with_thins(pool, size, *ids, &block)
  end

  # FIXME: simplify by lifting the pause
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
    assert_raise(ExitError) do
      @dm.with_dev(table) do |pool|
      end
    end
  end

  def with_mounts(fs, mount_points)
    if fs.length != mount_points.length
      raise "number of filesystems differs from number of mount points"
    end

    mounted = Array.new

    teardown = lambda do
      mounted.each {|fs| fs.umount}
    end

    bracket_(teardown) do
      0.upto(fs.length - 1) do |i|
        fs[i].mount(mount_points[i])
        mounted << fs[i]
      end

      yield
    end
  end

  def count_deferred_ios(&block)
    b = get_deferred_io_count
    block.call
    get_deferred_io_count - b
  end

  def reload_with_error_target(dev)
    dev.pause do
      dev.load(Table.new(Error.new(dev.active_table.size)))
    end
  end

  private
  def get_deferred_io_count
    ProcessControl.run("cat /sys/module/dm_thin_pool/parameters/deferred_io_count").to_i
  end

  def check_prereqs
    begin
      $prereqs.check
    rescue => e
      STDERR.puts e
      STDERR.puts "Missing prerequisites, please see the README"
      exit(1)
    end
  end
end

#----------------------------------------------------------------
