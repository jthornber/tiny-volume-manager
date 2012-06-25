require 'config'
require 'lib/blktrace'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/thinp-test'

#----------------------------------------------------------------

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# These tests rely on fsync_dev issuing a REQ_FLUSH to the device.
# Which it does in the thin-dev tree, but not vanilla Linux.
#
# Also the periodic commit *may* interfere if the system is very
# heavily loaded.
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# We track which thin devices have change and only commit metadata,
# triggered by a REQ_FLUSH or REQ_FUA, iff it has changed.  These
# tests use blktrace on the metadata dev to spot the superblock being
# rewritten in these cases.
class FlushTriggersCommitTests < ThinpTestCase
  include TinyVolumeManager
  include Utils
  include BlkTrace

  def committed?(&block)
    traces, _ = blktrace(@metadata_dev, &block)
    traces[0].member?(Event.new([:write], 0, 8))
  end

  def assert_commit(&block)
    flunk("expected commit") unless committed?(&block)
  end

  def assert_no_commit(&block)
    flunk("unexpected commit") if committed?(&block)
  end

  def do_commit_checks(dev)
    # Force a block to be provisioned
    assert_commit do
      wipe_device(dev, @data_block_size)
    end

    # the first block is provisioned now, so there shouldn't be a
    # subsequent commit.
    assert_no_commit do
      wipe_device(dev, @data_block_size)
    end
  end

  def test_commit_if_changed
    with_standard_pool(@size) do |pool|
      with_new_thins(pool, @volume_size, 0, 1) do |thin1, thin2|
        do_commit_checks(thin1)
        do_commit_checks(thin2)

        with_new_snap(pool, @volume_size, 2, 0) do |snap|
          do_commit_checks(thin1)
          do_commit_checks(snap)
        end
      end
    end
  end

  def test_discard_triggers_commit
    with_standard_pool(@size) do |pool|
      with_new_thins(pool, @volume_size, 0, 1) do |thin1, thin2|
        wipe_device(thin1, @data_block_size)
        wipe_device(thin2, @data_block_size)

        assert_commit do
          thin1.discard(0, @data_block_size)
        end

        do_commit_checks(thin1)

        assert_no_commit do
          wipe_device(thin2, @data_block_size)
        end
      end
    end    
  end
end
