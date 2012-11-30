require 'config'
require 'lib/git'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/cache-status'

require 'pp'

#----------------------------------------------------------------

module GitExtract
  TAGS = %w(v2.6.12 v2.6.13 v2.6.14 v2.6.15 v2.6.16 v2.6.17 v2.6.18 v2.6.19
            v2.6.20 v2.6.21 v2.6.22 v2.6.23 v2.6.24 v2.6.25 v2.6.26 v2.6.27 v2.6.28
            v2.6.29 v2.6.30 v2.6.31 v2.6.32 v2.6.33 v2.6.34 v2.6.35 v2.6.36 v2.6.37
            v2.6.38 v2.6.39 v3.0 v3.1 v3.2)

  def git_prepare_(dev, fs_type)
    fs = FS::file_system(fs_type, dev)
    STDERR.puts "formatting ..."
    fs.format

    fs.with_mount('./kernel_builds', :discard => true) do
      Dir.chdir('./kernel_builds') do
        STDERR.puts "getting repo ..."
        repo = Git.clone('/root/linux-github', 'linux')
      end
    end
  end

  def git_prepare(dev, fs_type)
    report_time("git_prepare", STDERR) {git_prepare_(dev, fs_type)}
  end

  def git_extract(dev, fs_type, tags = TAGS)
    fs_type = :ext4

    fs = FS::file_system(fs_type, dev)
    fs.with_mount('./kernel_builds', :discard => true) do
      Dir.chdir('./kernel_builds') do
        repo = Git.new('linux')

        repo.in_repo do
          report_time("extract all versions", STDERR) do
            tags.each do |tag|
              STDERR.puts "Checking out #{tag} ..."
              report_time("checking out #{tag}") do
                repo.checkout(tag)
                ProcessControl.run('sync')
                drop_caches
              end
            end
          end
        end
      end
    end
  end
end

#----------------------------------------------------------------

module DiskUnits
  def sectors(n)
    n
  end

  def meg(n)
    n * 2048
  end

  def gig(n)
    n * 2048 * 1024
  end
end

#----------------------------------------------------------------

class Policy
  attr_accessor :name, :opts

  def initialize(name, opts = Hash.new)
    @name = name
    @opts = opts
  end
end

#--------------------------------

class CacheStack
  include DiskUnits
  include ThinpTestMixin
  include Utils

  attr_accessor :tvm, :md, :ssd, :origin, :cache, :opts

  # options: :cache_size (in sectors), :block_size (in sectors),
  # :policy (class Policy), :format (bool), :origin_size (sectors)


  # FIXME: add methods for changing the policy + args

  def initialize(dm, ssd_dev, spindle_dev, opts)
    @dm = dm
    @ssd_dev = ssd_dev
    @spindle_dev = spindle_dev

    @md = nil
    @ssd = nil
    @origin = nil
    @cache = nil
    @opts = opts

    @tvm = TinyVolumeManager::VM.new
    @tvm.add_allocation_volume(ssd_dev, 0, dev_size(ssd_dev))
    @tvm.add_volume(linear_vol('md', meg(4)))

    cache_size = opts.fetch(:cache_size, meg(1024))
    @tvm.add_volume(linear_vol('ssd', cache_size))

    @data_tvm = TinyVolumeManager::VM.new
    @data_tvm.add_allocation_volume(spindle_dev, 0, dev_size(spindle_dev))
    @data_tvm.add_volume(linear_vol('origin', origin_size))
  end

  def activate(&block)
    with_devs(@tvm.table('md'),
              @tvm.table('ssd'),
              @data_tvm.table('origin')) do |md, ssd, origin|
      @md = md
      @ssd = ssd
      @origin = origin

      wipe_device(md, 8) if @opts.fetch(:format, true)

      with_dev(cache_table) do |cache|
        @cache = cache
        block.call(self)
      end
    end
  end

  def resize_ssd(new_size)
    @cache.pause do        # must suspend cache so resize is detected
      @ssd.pause do
        @tvm.resize('ssd', new_size)
        @ssd.load(@tvm.table('ssd'))
      end
    end
  end

  def resize_origin(new_size)
    @opts[:data_size] = new_size

    @cache.pause do
      @origin.pause do
        @data_tvm.resize('origin', new_size)
        @origin.load(@data_tvm.table('origin'))
      end
    end
  end

  def origin_size
    @opts.fetch(:data_size, dev_size(@spindle_dev))
  end

  def block_size
    @opts.fetch(:block_size, 512)
  end

  def policy
    @opts.fetch(:policy, Policy.new('default'))
  end

  def io_mode
    @opts.fetch(:io_mode, :writeback)
  end

  def cache_table
    Table.new(CacheTarget.new(origin_size, @md, @ssd, @origin,
                              block_size, [io_mode], policy.name, {}))
  end
end

#----------------------------------------------------------------

class CacheTests < ThinpTestCase
  include GitExtract
  include Tags
  include Utils
  include DiskUnits

  def setup
    super
    @data_block_size = meg(1)
  end

  #--------------------------------

  def with_standard_cache(opts = Hash.new, &block)
    stack = CacheStack.new(@dm, @metadata_dev, @data_dev, opts)
    stack.activate do |stack|
      block.call(stack.cache)
    end
  end

  def drop_caches
    ProcessControl.run('echo 3 > /proc/sys/vm/drop_caches')
  end

  #--------------------------------

  def test_dt_cache
    with_standard_cache(:format => true, :data_size => gig(1)) do |cache|
      dt_device(cache)
    end
  end

  def test_dt_linear
    with_standard_linear(:data_size => gig(1)) do |linear|
      dt_device(linear)
    end
  end

  def test_dd_cache
    with_standard_cache(:format => true, :data_size => gig(1)) do |cache|
      wipe_device(cache)
    end
  end

  def test_dd_linear
    with_standard_linear(:data_size => gig(1)) do |linear|
      wipe_device(linear)
    end
  end

  def do_fio(dev, fs_type)
    fs = FS::file_system(fs_type, dev)
    fs.format

    fs.with_mount('./fio_test', :discard => true) do
      Dir.chdir('./fio_test') do
        ProcessControl.run("fio ../tests/cache/fio.config")
      end
    end
  end

  def do_format(dev, fs_type)
    fs = FS::file_system(fs_type, dev)

    report_time("formatting", STDERR) do
      fs.format
    end

    report_time("mount/umount/fsck", STDERR) do
      fs.with_mount('./test_fs', :discard => true) do
      end
    end
  end

  def do_bonnie(dev, fs_type)
    fs = FS::file_system(fs_type, dev)
    fs.format
    fs.with_mount('./test_fs', :discard => true) do
      Dir.chdir('./test_fs') do
        report_time("bonnie++") do
          ProcessControl::run("bonnie++ -d . -u root -s 1024")
        end
      end
    end
  end

  def do_git_extract_cache_quick(opts)
    stack = CacheStack.new(@dm, @metadata_dev, @data_dev, opts)
    stack.activate do |stack|
      git_prepare(stack.cache, :ext4)
      git_extract(stack.cache, :ext4, TAGS[0..5])
    end
  end

  def test_git_extract_cache_quick
    do_git_extract_cache_quick(:policy => Policy.new('mq'), :cache_size => meg(1024))
  end

  def do_git_extract_only_cache_quick(opts)
    opts = {
      :policy     => opts.fetch(:policy, Policy.new('basic')),
      :cache_size => opts.fetch(:cache_size, meg(1024)),
      :data_size  => opts.fetch(:data_size, gig(2))
    }

    with_standard_linear(:data_size => opts.fetch(:data_size)) do |origin|
      git_prepare(origin, :ext4)
    end

    stack = CacheStack.new(@dm, @metadata_dev, @data_dev, opts)
    stack.activate do |stack|
      git_extract(stack.cache, :ext4, TAGS[0..5])
    end
  end

  def test_git_extract_only_cache_quick_mq
    do_git_extract_only_cache_quick(:policy => Policy.new('mq'))
  end

  def test_git_extract_only_cache_quick_multiqueue
    do_git_extract_only_cache_quick(:policy => Policy.new('multiqueue'))
  end

  def test_git_extract_only_cache_quick_multiqueue_ws
    do_git_extract_only_cache_quick(:policy => Policy.new('multiqueue_ws'))
  end

  def test_git_extract_only_cache_quick_q2
    do_git_extract_only_cache_quick(:policy => Policy.new('q2'))
  end

  def test_git_extract_only_cache_quick_twoqueue
    do_git_extract_only_cache_quick(:policy => Policy.new('twoqueue'))
  end

  def test_git_extract_only_cache_quick_fifo
    do_git_extract_only_cache_quick(:policy => Policy.new('fifo'))
  end

  def test_git_extract_only_cache_quick_filo
    do_git_extract_only_cache_quick(:policy => Policy.new('filo'))
  end

  def test_git_extract_only_cache_quick_lru
    do_git_extract_only_cache_quick(:policy => Policy.new('lru'))
  end

  def test_git_extract_only_cache_quick_mru
    do_git_extract_only_cache_quick(:policy => Policy.new('mru'))
  end

  def test_git_extract_only_cache_quick_lfu
    do_git_extract_only_cache_quick(:policy => Policy.new('lfu'))
  end

  def test_git_extract_only_cache_quick_mfu
    do_git_extract_only_cache_quick(:policy => Policy.new('mfu'))
  end

  def test_git_extract_only_cache_quick_lfu_ws
    do_git_extract_only_cache_quick(:policy => Policy.new('lfu_ws'))
  end

  def test_git_extract_only_cache_quick_mfu_ws
    do_git_extract_only_cache_quick(:policy => Policy.new('mfu_ws'))
  end

  def test_git_extract_only_cache_quick_random
    do_git_extract_only_cache_quick(:policy => Policy.new('random'))
  end

  def test_git_extract_only_cache_quick_dumb
    do_git_extract_only_cache_quick(:policy => Policy.new('dumb'))
  end

  def test_git_extract_only_cache_quick_debug
    do_git_extract_only_cache_quick(:policy => Policy.new('debug'))
  end


  def test_git_extract_cache_quick_mq
    do_git_extract_cache_quick(:policy => Policy.new('mq'))
  end

  def test_git_extract_cache_quick_mq_wt
    do_git_extract_cache_quick(:policy => Policy.new('mq'), :io_mode => :writethrough)
  end

  def test_git_extract_cache_quick_multiqueue
    do_git_extract_cache_quick(:policy => Policy.new('multiqueue'))
  end

  def test_git_extract_cache_quick_multiqueue_ws
    do_git_extract_cache_quick(:policy => Policy.new('multiqueue_ws'))
  end

  def test_git_extract_cache_quick_multiqueue_ws_wt
    do_git_extract_cache_quick(:policy => Policy.new('multiqueue_ws'), :io_mode => :writethrough)
  end

  def test_git_extract_cache_quick_q2
    do_git_extract_cache_quick(:policy => Policy.new('q2'))
  end

  def test_git_extract_cache_quick_twoqueue
    do_git_extract_cache_quick(:policy => Policy.new('twoqueue'))
  end

  def test_git_extract_cache_quick_fifo
    do_git_extract_cache_quick(:policy => Policy.new('fifo'))
  end

  def test_git_extract_cache_quick_filo
    do_git_extract_cache_quick(:policy => Policy.new('filo'))
  end

  def test_git_extract_cache_quick_lru
    do_git_extract_cache_quick(:policy => Policy.new('lru'))
  end

  def test_git_extract_cache_quick_mru
    do_git_extract_cache_quick(:policy => Policy.new('mru'))
  end

  def test_git_extract_cache_quick_lfu
    do_git_extract_cache_quick(:policy => Policy.new('lfu'))
  end

  def test_git_extract_cache_quick_mfu
    do_git_extract_cache_quick(:policy => Policy.new('mfu'))
  end

  def test_git_extract_cache_quick_lfu_ws
    do_git_extract_cache_quick(:policy => Policy.new('lfu_ws'))
  end

  def test_git_extract_cache_quick_mfu_ws
    do_git_extract_cache_quick(:policy => Policy.new('mfu_ws'))
  end

  def test_git_extract_cache_quick_random
    do_git_extract_cache_quick(:policy => Policy.new('random'))
  end

  def test_git_extract_cache_quick_dumb
    do_git_extract_cache_quick(:policy => Policy.new('dumb'))
  end

  def test_git_extract_cache_quick_noop
    do_git_extract_cache_quick(:policy => Policy.new('noop'))
  end

  def test_git_extract_cache_quick_debug_mq
    do_git_extract_cache_quick(:policy => Policy.new('debug'))
  end

  def test_git_extract_cache
    stack = CacheStack.new(@dm, @metadata_dev, @data_dev, :format => true)
    stack.activate do |stack|
      git_prepare(stack.cache, :ext4)
      git_extract(stack.cache, :ext4)
    end
  end

  def test_cache_sizing_effect
    cache_sizes = [64, 128, 192, 256, 320, 384, 448, 512,
                   576, 640, 704, 768, 832, 896, 960,
                   1024, 1088, 1152, 1216, 1280, 1344, 1408]

    cache_sizes.each do |size|
      do_git_extract_cache_quick(:cache_size => meg(size),
                                 :data_size => meg(1408))
    end
  end

  def test_git_extract_linear
    with_standard_linear do |linear|
      git_prepare(linear, :ext4)
      git_extract(linear, :ext4)
    end
  end

  def test_git_extract_linear_quick
    with_standard_linear do |linear|
      git_prepare(linear, :ext4)
      git_extract(linear, :ext4, TAGS[0..5])
    end
  end

  def test_fio_linear
    with_standard_linear do |linear|
      do_fio(linear, :ext4)
    end
  end

  def test_fio_cache
    with_standard_cache(:cache_size => meg(1024),
                        :format => true,
                        :block_size => 512,
                        :data_size => meg(1024),
                        :policy => Policy.new('mq')) do |cache|
      do_fio(cache, :ext4)
    end
  end

  def test_format_linear
    with_standard_linear do |linear|
      do_format(linear, :ext4)
    end
  end

  def test_format_cache
    with_standard_cache(:format => true, :policy => Policy.new('mq')) do |cache|
      do_format(cache, :ext4)
    end
  end

  def test_bonnie_linear
    with_standard_linear do |linear|
      do_bonnie(linear, :ext4)
    end
  end

  def test_bonnie_cache
    with_standard_cache(:cache_size => meg(256),
                        :format => true,
                        :block_size => 512,
                        :policy => Policy.new('mkfs')) do |cache|
      do_bonnie(cache, :ext4)
    end
  end

  # Checks we can remount an fs
  def test_metadata_persists
    with_standard_cache(:format => true) do |cache|
      fs = FS::file_system(:ext4, cache)
      fs.format
      fs.with_mount('./test_fs') do
        drop_caches
      end
    end


    with_standard_cache do |cache|
      fs = FS::file_system(:ext4, cache)
      fs.with_mount('./test_fs') do
      end
    end
  end

  def test_suspend_resume
    with_standard_cache(:format => true) do |cache|
      git_prepare(cache, :ext4)

      3.times do
        report_time("suspend/resume", STDERR) do
          cache.pause {}
        end
      end
    end
  end

  def test_table_reload
    with_standard_cache(:format => true) do |cache|
      table = cache.active_table

      git_prepare(cache, :ext4)

      cache.pause do
        cache.load(table)
      end
    end
  end

  def test_table_reload_changed_policy
    with_standard_cache(:format => true, :policy => Policy.new('mq')) do |cache|
      table = cache.active_table

      tid = Thread.new(cache) do
        git_prepare(cache, :ext4)
      end

      use_mq = false

      while tid.alive?
        sleep 5
        cache.pause do
          table.targets[0].args[6] = use_mq ? 'mq' : 'writeback'
          cache.load(table)
          use_mq = !use_mq
        end
      end

      tid.join
    end
  end

  def test_cache_grow
    stack = CacheStack.new(@dm, @metadata_dev, @data_dev,
                           :format => true,
                           :cache_size => meg(16))
    stack.activate do |stack|
      tid = Thread.new(stack.cache) do
        git_prepare(stack.cache, :ext4)
      end

      [256, 512, 768, 1024].each do |size|
        sleep 10
        resize_ssd(stack, meg(size))
      end

      tid.join
    end
  end

  def test_dt_cache
    with_standard_cache(:format => true, :policy => Policy.new('mq')) do |cache|
      dt_device(cache)
    end
  end

  def test_unknown_policy_fails
    assert_raise(ExitError) do
      with_standard_cache(:format => true,
                          :policy => Policy.new('time_traveller')) do |cache|
      end
    end
  end

  def wait_for_all_clean(cache)
    cache.event_tracker.wait(cache) do |cache|
      status = CacheStatus.new(cache)
      STDERR.puts "#{status.nr_dirty} dirty blocks"
      status.nr_dirty == 0
    end
  end

  def test_writeback_policy
    with_standard_cache(:format => true) do |cache|
      git_prepare(cache, :ext4)

      cache.pause do
        table = cache.active_table
        table.targets[0].args[6] = 'writeback'
        cache.load(table)
      end

      wait_for_all_clean(cache)
    end

    # We should be able to use the origin directly now
    with_standard_linear do |origin|
      fs = FS::file_system(:ext4, origin)
      fs.with_mount('./kernel_builds', :discard => true) do
        # triggers fsck
      end
    end
  end

  def test_construct_cache
    stack = CacheStack.new(@dm, @metadata_dev, @data_dev, :format => true)
    stack.activate do |stack|
    end
  end

  def test_writethrough
    size = gig(2)

    # wipe the origin to ensure we don't accidentally have the same
    # data on it.
    with_standard_linear(:data_size => size) do |origin|
      wipe_device(origin)
    end

    # format and set up a git repo on the cache
    with_standard_cache(:format => true,
                        :io_mode => :writethrough,
                        :data_size => size) do |cache|
      git_prepare(cache, :ext4)
    end

    # origin should have all data
    with_standard_linear(:data_size => size) do |origin|
      git_extract(origin, :ext4, TAGS[0..1])
    end
  end

  def test_origin_grow
    # format and set up a git repo on the cache
    stack = CacheStack.new(@dm, @metadata_dev, @data_dev,
                           :format => true,
                           :io_mode => :writethrough,
                           :data_size => gig(2))
    stack.activate do |stack|
      git_prepare(stack.cache, :ext4)
      stack.resize_origin(gig(3))
      git_extract(stack.cache, :ext4, TAGS[0..1])
    end
  end

  def test_origin_shrink
    # format and set up a git repo on the cache
    stack = CacheStack.new(@dm, @metadata_dev, @data_dev,
                           :format => true,
                           :io_mode => :writethrough,
                           :data_size => gig(3))
    stack.activate do |stack|
      git_prepare(stack.cache, :ext4)
      stack.resize_origin(gig(2))
      git_extract(stack.cache, :ext4, TAGS[0..1])
    end
  end  
end
