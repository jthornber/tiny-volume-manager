require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class BasicTests < ThinpTestCase
  include Tags
  include Utils

  def setup
    super
  end

  tag :thinp_target

  def test_overwrite_a_linear_device
    linear_table = Table.new(Linear.new(@volume_size, @data_dev, 0))
    @dm.with_dev(linear_table) do |linear_dev|
      dt_device(linear_dev)
    end
  end

  def test_ext4_weirdness
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        thin_fs = FS::file_system(:ext4, thin)
        thin_fs.format

        thin.pause do
          pool.message(0, "create_snap 1 0")
        end

        dt_device(thin)
      end
    end
  end

  tag :thinp_target, :slow

  def test_overwriting_various_thin_devices
    # we keep tearing down the pool and setting it back up so that we
    # can trigger a thin_repair check at each stage.

    info "dt an unprovisioned thin device"
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) do |thin|
        dt_device(thin)
      end
    end

    info "dt a fully provisioned thin device"
    with_standard_pool(@size) do |pool|
      with_thin(pool, @volume_size, 0) do |thin|
        dt_device(thin)
      end
    end

    info "dt a snapshot of a fully provisioned device"
    with_standard_pool(@size) do |pool|
      with_new_snap(pool, @volume_size, 1, 0) do |snap|
        dt_device(snap)
      end
    end

    info "dt a snapshot with no sharing"
    with_standard_pool(@size) do |pool|
      with_thin(pool, @volume_size, 1) do |snap|
        dt_device(snap)
      end
    end
  end
end

#----------------------------------------------------------------
