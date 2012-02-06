require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/status'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/xml_format'

#----------------------------------------------------------------

class HeldRootTests < ThinpTestCase
  include Tags
  include Utils
  include XMLFormat

  def get_root(pool)
    status = PoolStatus.new(pool)
    status.held_root
  end

  def assert_root_set(pool)
    root = get_root(pool)
    assert(!root.nil? && root != 0)
  end

  def assert_root_unset(pool)
    assert_equal(nil, get_root(pool))
  end

  def test_hold_release_cycle_empty_pool
    with_standard_pool(@size) do |pool|
      assert_root_unset(pool)
      pool.message(0, "hold_root")
      assert_root_set(pool)
      pool.message(0, "release_root")
      assert_root_unset(pool)
    end
  end

  def test_cannot_hold_twice
    with_standard_pool(@size) do |pool|
      pool.message(0, "hold_root")
      assert_raises(RuntimeError) do
        pool.message(0, "hold_root")
      end
    end
  end

  def test_cannot_release_twice
    with_standard_pool(@size) do |pool|
      pool.message(0, "hold_root")
      pool.message(0, "release_root")

      assert_raises(RuntimeError) do
        pool.message(0, "release_root")
      end
    end
  end

  def test_no_initial_hold
    with_standard_pool(@size) do |pool|
      assert_raises(RuntimeError) do
        pool.message(0, "release_root")
      end
    end
  end

  def test_held_root_changes
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin, 4)
        pool.message(0, "hold_root")
        root1 = get_root(pool)
        wipe_device(thin, 8)
        pool.message(0, "release_root")
        pool.message(0, "hold_root")
        assert(root1 != get_root(pool))
      end
    end
  end    

  def test_benchmark
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin)
        wipe_device(thin)
        pool.message(0, "hold_root")
        wipe_device(thin)
        pool.message(0, "release_root")
        wipe_device(thin)
        wipe_device(thin)
      end
    end
  end
end
