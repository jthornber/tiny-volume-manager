require 'lib/bufio'
require 'lib/log'
require 'lib/process'
require 'test/unit'

#----------------------------------------------------------------

$checked_prerequisites = false

class ThinpTestCase < Test::Unit::TestCase
  undef_method :default_test
  include ProcessControl

  def setup
    check_prereqs()

    config = Config.get_config
    @metadata_dev = config[:metadata_dev]
    @data_dev = config[:data_dev]

    @data_block_size = config[:data_block_size]
    @data_block_size = 128 if @data_block_size.nil?

    @size = config[:data_size]
    @size = 20971520 if @size.nil?
    @size /= @data_block_size
    @size *= @data_block_size

    @volume_size = config[:volume_size]
    @volume_size = 2097152 if @volume_size.nil?

    @tiny_size = @data_block_size

    @low_water_mark = config[:low_water_mark]
    @low_water_mark = 5 if @low_water_mark.nil?

    @mass_fs_tests_parallel_runs = config[:mass_fs_tests_parallel_runs]
    @mass_fs_tests_parallel_runs = 128 if @mass_fs_tests_parallel_runs.nil?

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

  def dflt(h, k, d)
    h.member?(k) ? h[k] : d
  end

  def with_standard_pool(size, opts = Hash.new)
    zero = dflt(opts, :zero, true)
    discard = dflt(opts, :discard, true)
    discard_pass = dflt(opts, :discard_passdown, true)

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water_mark, zero, discard, discard_pass))

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

  def with_thin(pool, size, id, opts = Hash.new)
    @dm.with_dev(Table.new(Thin.new(size, pool, id, opts[:origin]))) do |thin|
      yield(thin)
    end
  end

  def with_new_thin(pool, size, id, opts = Hash.new, &block)
    pool.message(0, "create_thin #{id}")
    with_thin(pool, size, id, opts, &block)
  end

  def with_thins(pool, size, *ids, &block)
    tables = ids.map {|id| Table.new(Thin.new(size, pool, id))}
    @dm.with_devs(*tables, &block)
  end

  def with_new_thins(pool, size, *ids, &block)
    ids.each do |id|
      pool.message(0, "create_thin #{id}")
    end

    with_thins(pool, size, *ids, &block)
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

  def with_mounts(fs, mount_points)
    if fs.length != mount_points.length
      raise RuntimeError, "number of filesystems differs from number of mount points"
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

  def time_block
    start_time = Time.now
    yield
    return Time.now - start_time
  end

  def report_time(desc, &block)
    elapsed = time_block(&block)
    info "Elapsed #{elapsed}: #{desc}"
  end

  def trans_id(pool)
    PoolStatus.new(pool).transaction_id
  end

  def set_trans_id(pool, old, new)
    pool.message(0, "set_transaction_id #{old} #{new}")
  end

  def count_deferred_ios(&block)
    b = get_deferred_io_count
    block.call
    get_deferred_io_count - b
  end

  def assert_identical_files(f1, f2)
    begin
      ProcessControl::run("diff -bu #{f1} #{f2}")
    rescue
      flunk("files differ #{f1} #{f2}")
    end
  end

  # Reads the metadata from an _inactive_ pool
  def dump_metadata(dev)
    metadata = nil
    Utils::with_temp_file('metadata_xml') do |file|
      ProcessControl::run("thin_dump -i #{dev} > #{file.path}")
      file.rewind
      yield(file.path)
    end
  end

  def restore_metadata(xml_path, dev)
    ProcessControl::run("thin_restore -i #{xml_path} -o #{dev}")
  end

  private
  def get_deferred_io_count
    ProcessControl.run("cat /sys/module/dm_thin_pool/parameters/deferred_io_count").to_i
  end

  def check_prereqs
    return if $checked_prerequisites

    # Can we find thin_check?
    begin
      raise "wrong ruby version" unless RUBY_VERSION =~ /^1.8/
      ProcessControl.run('which thin_check')
      ProcessControl.run('which dt')
      ProcessControl.run('which blktrace')
    rescue
      STDERR.puts "Missing prerequisites, please check the README"
      exit(1)
    end

    $checked_prerequisites = true
  end
end

#----------------------------------------------------------------
