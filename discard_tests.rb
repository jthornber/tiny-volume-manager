require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/status'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/xml_format'
require 'set'

#----------------------------------------------------------------

class DiscardTests < ThinpTestCase
  include Tags
  include Utils
  include XMLFormat

  def setup
    super
    @blocks_per_dev = div_up(@volume_size, @data_block_size)
    @volume_size = @blocks_per_dev * @data_block_size # we want whole blocks for these tests
  end

  def read_metadata(metadata_dev = nil)
    dump_metadata(metadata_dev.nil? ? @metadata_dev : metadata_dev) do |xml_path|
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
    sleep(2)                # sleep long enough for a commit, so we know the used count is up to date
    assert_equal(count, used_data_blocks(pool))
  end

  def test_discard_empty_device
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        thin.discard(0, @volume_size)
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

  def test_discard_partial_blocks
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin)

        thin.discard(0, 127)
        thin.discard(63, 159)
      end
    end

    md = read_metadata
    assert_fully_mapped(md, 0)
  end

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

  def discard(thin, b, len)
    b_sectors = b * @data_block_size
    len_sectors = len * @data_block_size

    thin.discard(b_sectors, [len_sectors, @volume_size - b_sectors].min)
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

  #
  # set up 2 level pool stack to provison and discard a thin device
  # at the upper level and allow for enabling/disabling
  # discards and discard_passdown at any level
  #
  def do_discard_levels(levels = Hash.new)
    with_standard_pool(@size, {:discard => levels[:lower], :discard_passdown => levels[:lower_passdown]}) do |lower|
      with_new_thin(lower, @size, 0) do |lower_thin|
        with_pool_volume(lower_thin, @size - @low_water_mark * @data_block_size, {:discard => levels[:upper], :discard_passdown => levels[:upper_passdown]}) do |upper_thin, upper, upper_blocks, meta_blocks|
          # provison the whole thin dev and discard half of its blocks
          upper_blocks_discard = div_up(upper_blocks, 2)
          upper_blocks_used = upper_blocks - upper_blocks_discard
          wipe_device(upper_thin)
  
          # assert results for combinations
          if (levels[:upper])
            upper_thin.discard(0, upper_blocks_discard * @data_block_size)
            assert_equal(upper_blocks_used, used_data_blocks(upper))
          else
            assert_raises(Errno::EOPNOTSUPP) do
              upper_thin.discard(0, upper_blocks_discard * @data_block_size)
              assert_equal(upper_blocks, used_data_blocks(upper))
            end
          end

          if (levels[:lower])
            if (levels[:upper_passdown])
              assert_equal(upper_blocks_used, used_data_blocks(lower) - meta_blocks)
            else
              assert_equal(upper_blocks, used_data_blocks(lower) - meta_blocks)
            end
          else
            assert_equal(upper_blocks, used_data_blocks(lower) - meta_blocks)
          end
        end
      end
    end
  end

  def test_discard_lower_both_upper_both
    do_discard_levels({:lower => true, :lower_passdown => true,
                       :upper => true, :upper_passdown => true})
  end

  def test_discard_lower_none_upper_both
    do_discard_levels({:lower => false, :lower_passdown => false,
                       :upper => true,  :upper_passdown => true})
  end

  def test_discard_lower_both_upper_none
    do_discard_levels({:lower => true,  :lower_passdown => true,
                       :upper => false, :upper_passdown => false})
  end

  def test_discard_lower_none_upper_none
    do_discard_levels({:lower => false, :lower_passdown => false,
                       :upper => false, :upper_passdown => false})
  end

  def test_discard_lower_both_upper_discard
    do_discard_levels({:lower => true, :lower_passdown => true,
                       :upper => true, :upper_passdown => false})
  end

  def test_discard_lower_discard_upper_both
    do_discard_levels({:lower => true, :lower_passdown => false,
                       :upper => true, :upper_passdown => true})
  end
end
