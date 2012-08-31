require 'config'
require 'lib/blktrace'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/status'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/xml_format'
require 'set'

#----------------------------------------------------------------

module DiscardMixin
  include Utils
  include XMLFormat
  include BlkTrace
  include TinyVolumeManager

  def setup
    super
    @blocks_per_dev = div_up(@volume_size, @data_block_size)
    @volume_size = @blocks_per_dev * @data_block_size # we want whole blocks for these tests
  end

  def read_metadata
    dump_metadata(@metadata_dev) do |xml_path|
      File.open(xml_path, 'r') do |io|
        read_xml(io)            # this is the return value
      end
    end
  end

  def with_dev_md(md, thin_id, &block)
    md.devices.each do |dev|
      next unless dev.dev_id == thin_id

      return block.call(dev)
    end
  end

  def assert_no_mappings(md, thin_id)
    with_dev_md(md, thin_id) do |dev|
      assert_equal(0, dev.mapped_blocks)
      assert_equal([], dev.mappings)
    end
  end

  def assert_fully_mapped(md, thin_id)
    with_dev_md(md, thin_id) do |dev|
      assert_equal(@blocks_per_dev, dev.mapped_blocks)
    end
  end

  # The block should be a predicate that says whether a given block
  # should be provisioned.
  def check_provisioned_blocks(md, thin_id, size, &block)
    provisioned_blocks = Array.new(size, false)

    with_dev_md(md, thin_id) do |dev|
      dev.mappings.each do |m|
        m.origin_begin.upto(m.origin_begin + m.length - 1) do |b|
          provisioned_blocks[b] = true
        end
      end
    end

    0.upto(size - 1) do |b|
      assert_equal(block.call(b), provisioned_blocks[b],
                   "bad provision status for block #{b}")
    end
  end

  def used_data_blocks(pool)
    s = PoolStatus.new(pool)
    STDERR.puts "pool status metadata(#{s.used_metadata_blocks}/#{s.total_metadata_blocks}) data(#{s.used_data_blocks}/#{s.total_data_blocks})"
    s.used_data_blocks
  end

  def assert_used_blocks(pool, count)
    assert_equal(count, used_data_blocks(pool))
  end

  def discard(thin, b, len)
    b_sectors = b * @data_block_size
    len_sectors = len * @data_block_size

    thin.discard(b_sectors, [len_sectors, @volume_size - b_sectors].min)
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def define_test_over_bs(name, *bs, &block)
      bs.each do |block_size|
        define_method("test_#{name}_bs#{block_size}".intern) do
          @data_block_size = block_size
          @blocks_per_dev = div_up(@volume_size, @data_block_size)
          @volume_size = @blocks_per_dev * @data_block_size # we want whole blocks for these tests

          yield(block_size, @volume_size)
        end
      end
    end
  end

  def check_discard_passdown_enabled(pool, data_dev)
    with_new_thin(pool, @volume_size, 0) do |thin|
      wipe_device(thin, 8)

      traces, _ = blktrace(thin, data_dev) do
        discard(thin, 0, 1)
      end

      assert_discards(traces[0], 0,  @data_block_size)
      assert_discards(traces[1], 0,  @data_block_size)
    end
  end

  def check_discard_passdown_disabled(pool, data_dev)
    with_new_thin(pool, @volume_size, 0) do |thin|
      wipe_device(thin, 8)

      traces, _ = blktrace(thin, data_dev) do
        discard(thin, 0, 1)
      end

      assert_discards(traces[0], 0,  @data_block_size)
      assert(traces[1].empty?)
    end
  end

  def check_discard_thin_working(thin)
      wipe_device(thin, 8)
      traces, _ = blktrace(thin) do
        discard(thin, 0, 1)
      end
      assert_discards(traces[0], 0,  @data_block_size)
  end
end

#----------------------------------------------------------------

class DiscardQuickTests < ThinpTestCase
  include DiscardMixin

  def test_discard_empty_device
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        thin.discard(0, @volume_size)

#  DiscardMixin::define_test_over_bs(:discard_empty_device, 128, 192)  do |block_size, volume_size|
#    with_standard_pool(@size, :block_size => block_size) do |pool|
#      with_new_thin(pool, volume_size, 0) do |thin|
#        thin.discard(0, volume_size)

        assert_used_blocks(pool, 0)
      end
    end

    md = read_metadata
    assert_no_mappings(md, 0)
  end

  def test_discard_fully_provisioned_device
    with_standard_pool(@size) do |pool|
      with_new_thins(pool, @volume_size, 0, 1) do |thin, thin2|
        wipe_device(thin)
        wipe_device(thin2)
        assert_used_blocks(pool, 2 * @blocks_per_dev)
        thin.discard(0, @volume_size)
        assert_used_blocks(pool, @blocks_per_dev)
      end
    end

    md = read_metadata
    assert_no_mappings(md, 0)
    assert_fully_mapped(md, 1)
  end

  def test_discard_single_block
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin)
        assert_used_blocks(pool, @blocks_per_dev)
        thin.discard(0, @data_block_size)
        assert_used_blocks(pool, @blocks_per_dev - 1)
      end
    end

    md = read_metadata
    check_provisioned_blocks(md, 0, @blocks_per_dev) do |b|
      b == 0 ? false : true
    end
  end

  # If a block is shared we can unmap the block, but must not pass the
  # discard down to the underlying device.
  def test_discard_to_a_shared_block_doesnt_get_passed_down
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin, @data_block_size)

        assert_used_blocks(pool, 1)

        with_new_snap(pool, @volume_size, 1, 0, thin) do |snap|
          assert_used_blocks(pool, 1)
          traces, _ = blktrace(thin, snap, @data_dev) do
            thin.discard(0, @data_block_size)
          end

          thin_trace, snap_trace, data_trace = traces
          event = Event.new([:discard], 0, @data_block_size)
          assert(thin_trace.member?(event))
          assert(!snap_trace.member?(event))
          assert(!data_trace.member?(event))

          assert_used_blocks(pool, 1)
        end
      end
    end
  end

  def test_discard_partial_blocks
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin)

        thin.discard(0, 120)
        thin.discard(56, 160)
      end
    end

    md = read_metadata
    assert_fully_mapped(md, 0)
  end

  def test_disable_discard
    with_standard_pool(@size, :discard => false) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin, 4)

        assert_raise(Errno::EOPNOTSUPP) do
          thin.discard(0, @data_block_size)
        end
      end
    end
  end

  def test_enable_passdown
    with_standard_pool(@size, :discard_passdown => true) do |pool|
      check_discard_passdown_enabled(pool, @data_dev)
    end

    md = read_metadata
    assert_no_mappings(md, 0)
  end

  def _test_disable_passdown
    with_standard_pool(@size, :discard_passdown => false) do |pool|
      check_discard_passdown_disabled(pool, @data_dev)
    end

    md = read_metadata
    assert_no_mappings(md, 0)
  end

  # we don't allow people to change their minds about top level
  # discard support.
  def test_change_discard_with_reload_fails
    with_standard_pool(@size, :discard => true) do |pool|
      assert_raise(ExitError) do
        table = Table.new(ThinPoolTarget.new(@size, @metadata_dev, @data_dev,
                                             @data_block_size, @low_water_mark, false, false, false))
        pool.load(table)
      end
    end

    with_standard_pool(@size, :discard => false) do |pool|
      assert_raise(ExitError) do
        table = Table.new(ThinPoolTarget.new(@size, @metadata_dev, @data_dev,
                                             @data_block_size, @low_water_mark, false, true, false))
        pool.load(table)
      end
    end
  end
end

#----------------------------------------------------------------

class DiscardSlowTests < ThinpTestCase
  include DiscardMixin

  def test_discard_alternate_blocks
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin)

        b = 0
        while b < @blocks_per_dev
          thin.discard(b * @data_block_size, @data_block_size)
          b += 2
        end
      end
    end

    md = read_metadata
    check_provisioned_blocks(md, 0, @blocks_per_dev) {|b| b.odd?}
  end

  def do_discard_random_sectors(duration)
    start = Time.now
    threshold_blocks = @blocks_per_dev / 3

    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        while (Time.now - start) < duration

          # FIXME: hack to force a commit
          # pool.message(0, 'create_thin 1')
          # pool.message(0, 'delete 1')

          if used_data_blocks(pool) < threshold_blocks
            STDERR.puts "#{Time.now} wiping dev"
            wipe_device(thin) # provison in case of too few mappings
          end

          STDERR.puts 'entering discard loop'
          10000.times do
            s = rand(@blocks_per_dev - 1)
            s_len = 1 + rand(5)

            discard(thin, s, s_len)
          end
        end
      end
    end
  end

  def test_discard_random_sectors
    do_discard_random_sectors(10 * 60)
  end

  def with_stacked_pools(levels, &block)
    # create 2 metadata devs
    tvm = VM.new
    tvm.add_allocation_volume(@metadata_dev, 0, dev_size(@metadata_dev))

    md_size = tvm.free_space / 2
    tvm.add_volume(linear_vol('md1', md_size))
    tvm.add_volume(linear_vol('md2', md_size))

    with_devs(tvm.table('md1'),
              tvm.table('md2')) do |md1, md2|
      wipe_device(md1, 8)
      wipe_device(md2, 8)

      t1 = Table.new(ThinPoolTarget.new(@volume_size, md1, @data_dev, @data_block_size, 0, true, levels[:lower], levels[:lower_passdown]))
      @dm.with_dev(t1) do |lower_pool|
        with_new_thin(lower_pool, @volume_size, 0) do |lower_thin|
          t2 = Table.new(ThinPoolTarget.new(@volume_size, md2, lower_thin, @data_block_size, 0, true, levels[:upper], levels[:upper_passdown]))
          @dm.with_dev(t2) do |upper_pool|
            with_new_thin(upper_pool, @volume_size, 0) do |upper_thin|
              block.call(lower_pool, lower_thin, upper_pool, upper_thin)
            end
          end
        end
      end
    end
  end

  #
  # set up 2 level pool stack to provison and discard a thin device
  # at the upper level and allow for enabling/disabling
  # discards and discard_passdown at any level
  #
  def do_discard_levels(levels = Hash.new)
    with_stacked_pools(levels) do |lpool, lthin, upool, uthin|
      # provison the whole thin dev and discard half of its blocks_used
      total = div_up(@volume_size, @data_block_size)
      discard_count = total / 2
      remaining = total - discard_count

      wipe_device(uthin)
      assert_equal(total, used_data_blocks(upool))
      assert_equal(total, used_data_blocks(lpool))

      # assert results for combinations
      if (levels[:upper])
        0.upto(discard_count - 1) {|b| discard(uthin, b, 1)}
        assert_equal(remaining, used_data_blocks(upool))
      else
        assert_raise(Errno::EOPNOTSUPP) do
          discard(uthin, 0, discard_count)
        end

        assert_equal(total, used_data_blocks(upool))
      end

      if (levels[:lower])
        if (levels[:upper_passdown])
          assert_equal(remaining, used_data_blocks(lpool))
        else
          assert_equal(total, used_data_blocks(lpool))
        end
      else
        assert_equal(total, used_data_blocks(lpool))
      end
    end
  end

  def test_discard_lower_both_upper_both
    do_discard_levels(:lower => true,
                      :lower_passdown => true,
                      :upper => true,
                      :upper_passdown => true)
  end

  def test_discard_lower_none_upper_both
    do_discard_levels(:lower => false,
                      :lower_passdown => false,
                      :upper => true,
                      :upper_passdown => true)
  end

  def test_discard_lower_both_upper_none
    do_discard_levels(:lower => true,
                      :lower_passdown => true,
                      :upper => false,
                      :upper_passdown => false)
  end

  def test_discard_lower_none_upper_none
    do_discard_levels(:lower => false,
                      :lower_passdown => false,
                      :upper => false,
                      :upper_passdown => false)
  end

  def test_discard_lower_both_upper_discard
    do_discard_levels(:lower => true,
                      :lower_passdown => true,
                      :upper => true,
                      :upper_passdown => false)
  end

  def test_discard_lower_discard_upper_both
    do_discard_levels(:lower => true,
                      :lower_passdown => false,
                      :upper => true,
                      :upper_passdown => true)
  end

  def create_and_delete_lots_of_files(dev, fs_type)
    fs = FS::file_system(fs_type, dev)
    fs.format
    fs.with_mount("./mnt1", :discard => true) do
      ds = Dataset.read('compile-bench-datasets/dataset-unpatched')
      Dir.chdir('mnt1') do
        Dir.mkdir('linux')
        Dir.chdir('linux') do
          10.times do
            STDERR.write "."
            ds.apply
            ProcessControl.run("sync")
            ProcessControl.run("rm -rf *")
            ProcessControl.run("sync")
          end
        end
      end
    end
  end

  def do_discard_test(fs_type)
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        create_and_delete_lots_of_files(thin, fs_type)
      end
    end
  end

  def test_fs_discard_ext4
    do_discard_test(:ext4)
  end

  def test_fs_discard_xfs
    do_discard_test(:xfs)
  end
end

#----------------------------------------------------------------

class FakeDiscardTests < ThinpTestCase
  include DiscardMixin

  def test_fake_discard_hello_world
    with_fake_discard(:granularity => 128, :max_discard_sectors => 512) do |fd_dev|
      with_custom_data_pool(fd_dev, @size) do |pool|
        with_new_thin(pool, @volume_size, 0) do |thin|
          check_discard_thin_working(thin)
        end
      end
    end
  end

  def test_fake_discard_pool_granularity_matches_data_dev
    # when discard_passdown is enabled
    pool_bs = 512
    with_fake_discard(:granularity => 128, :max_discard_sectors => pool_bs) do |fd_dev|
      with_custom_data_pool(fd_dev, @size, :discard_passdown => true,
                            :block_size => pool_bs) do |pool|

        assert_equal(fd_dev.queue_limit(:discard_granularity),
                     pool.queue_limit(:discard_granularity))
        assert_equal(pool.queue_limit(:discard_max_bytes), pool_bs * 512)

        # verify discard passdown is still enabled
        check_discard_passdown_enabled(pool, fd_dev)
      end
    end
  end

  def test_fake_discard_pool_granularity_is_factor_of_np2_blocksize_no_passdown
    # e.g. blocksize = 384k, discard_granularity = 128k
    pool_bs = 768
    with_fake_discard(:granularity => 128, :max_discard_sectors => pool_bs) do |fd_dev|
      with_custom_data_pool(fd_dev, @size, :discard_passdown => false,
                            :block_size => pool_bs) do |pool|
        assert_equal(pool.queue_limit(:discard_granularity), 256 * 512)
        assert_equal(pool.queue_limit(:discard_max_bytes), pool_bs * 512)
        check_discard_passdown_disabled(pool, fd_dev)
      end
    end
  end

  def test_fake_discard_pool_max_and_granularity_match_pow2_block_size_no_passdown
    # e.g. blocksize = 384k, discard_granularity = 128k
    pool_bs = 512
    with_fake_discard(:granularity => 128, :max_discard_sectors => 768) do |fd_dev|
      with_custom_data_pool(fd_dev, @size, :discard_passdown => false,
                            :block_size => pool_bs) do |pool|
        assert_equal(pool.queue_limit(:discard_granularity), pool_bs * 512)
        assert_equal(pool.queue_limit(:discard_max_bytes), pool_bs * 512)
        check_discard_passdown_disabled(pool, fd_dev)
      end
    end
  end

  def test_fake_discard_data_max_smaller_than_block_size_disables_passdown
    pool_bs = 512
    with_fake_discard(:granularity => 128, :max_discard_sectors => 256) do |fd_dev|
      with_custom_data_pool(fd_dev, @size, :discard_passdown => true,
                            :block_size => pool_bs) do |pool|
        assert_equal(pool.queue_limit(:discard_granularity), pool_bs * 512)
        assert_equal(pool.queue_limit(:discard_max_bytes), pool_bs * 512)
        check_discard_passdown_disabled(pool, fd_dev)
      end
    end
  end

  def test_fake_discard_data_granularity_larger_than_block_size_disables_passdown
    pool_bs = 256
    with_fake_discard(:granularity => 512, :max_discard_sectors => 512) do |fd_dev|
      with_custom_data_pool(fd_dev, @size, :discard_passdown => true,
                            :block_size => pool_bs) do |pool|
        assert_equal(pool.queue_limit(:discard_granularity), pool_bs * 512)
        assert_equal(pool.queue_limit(:discard_max_bytes), pool_bs * 512)
        check_discard_passdown_disabled(pool, fd_dev)
      end
    end
  end

  def test_fake_discard_data_granularity_not_factor_of_block_size_disables_passdown
    # e.g. blocksize = 384k, discard_granularity = 256k
    # (this also tests largest_power_factor adjusts granularity, to 128k)
    pool_bs = 768
    with_fake_discard(:granularity => 512, :max_discard_sectors => 512) do |fd_dev|
      with_custom_data_pool(fd_dev, @size, :discard_passdown => true,
                            :block_size => pool_bs) do |pool|
        assert_equal(pool.queue_limit(:discard_granularity), 256 * 512)
        assert_equal(pool.queue_limit(:discard_max_bytes), pool_bs * 512)
        check_discard_passdown_disabled(pool, fd_dev)
      end
    end
  end

end
#----------------------------------------------------------------
