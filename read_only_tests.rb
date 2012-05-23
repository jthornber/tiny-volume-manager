require 'config'
require 'lib/blktrace'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class ReadOnlyTests < ThinpTestCase
  include Tags
  include TinyVolumeManager
  include Utils

  def test_create_read_only
    # we have to create a valid metadata dev first
    with_standard_pool(@size) do |pool|
    end

    # now we open it read-only
    with_standard_pool(@size, :read_only => true) do |pool|
    end
  end

  def test_can_access_fully_mapped_device
    # we have to create a valid metadata dev first
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin)
      end
    end

    # now we open it read-only
    with_standard_pool(@size, :read_only => true) do |pool|
      with_thin(pool, @volume_size, 0) do |thin|
        wipe_device(thin)
      end
    end
  end

  def test_cant_provision_new_blocks
    # we have to create a valid metadata dev first
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
      end
    end

    # now we open it read-only
    with_standard_pool(@size, :read_only => true) do |pool|
      with_thin(pool, @volume_size, 0) do |thin|
        assert_raise(ExitError) do
          wipe_device(thin)
        end
      end
    end
  end

  def test_cant_create_new_thins
    # we have to create a valid metadata dev first
    with_standard_pool(@size) do |pool|
    end

    # now we open it read-only
    with_standard_pool(@size, :read_only => true) do |pool|
      assert_raise(ExitError) do
        with_new_thin(pool, @volume_size, 0) do |thin|
        end
      end
    end
  end

  def test_cant_delete_thins
    # we have to create a valid metadata dev first
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
      end
    end

    # now we open it read-only
    with_standard_pool(@size, :read_only => true) do |pool|
      assert_raise(ExitError) do
        pool.message(0, "delete 0");
      end
    end
  end
end
