require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/status'
require 'lib/utils'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class MassFsTests < ThinpTestCase
  include Tags
  include Utils

  tag :thinp_target, :slow

  # format, fsck, mount, copy, umount, fsck
  def fs_cycle(dev, fs_type, mount_point)
    fs = FS::file_system(fs_type, dev)
    fs.format
    fs.check
    with_mount(fs, mount_point) do |mp|
      ProcessControl.run("rsync -lr /usr/bin #{mp} > /dev/null; sync")
    end
  end

  #
  # bulk configuration followed by load
  #
  def _mass_create_apply_remove(fs_type, max = nil)
    max = 2 if max.nil?
    ids = (1..max).entries
    dir = Dir.getwd

    with_standard_pool(@size) do |pool|
      with_new_thins(pool, @volume_size, *ids) do |*thins|
        in_parallel(*thins) do |thin|
          mount_point = "#{dir}/mnt_#{dev.name}"
        end
      end
    end

    ids.each { |i| pool.message(0, "delete #{i}") }
    assert_equal(@size, PoolStatus.new(pool).free_data_sectors)
  end

  def test_mass_create_apply_remove_ext4
    _mass_create_apply_remove(:ext4, 16)
  end

  def test_mass_create_apply_remove_xfs
    _mass_create_apply_remove(:xfs, 16)
  end

  #
  # configuration changes under load
  #
  def _config_load_one(pool, id, fs_type)
    pool.message(0, "create_thin #{id}")

    with_thin(pool, @volume_size, id) do |thin|
      fs = FS::file_system(fs_type, thin)
      fs.format
      fs.check
      fs.with_mount("mnt#{id}") do
        dt_device("mnt#{id}/tstfile")
      end
    end

    pool.message(0, "delete #{id}")
  end

  def _mass_create_apply_remove_with_config_load(fs_type, max = nil)
    max = 2 if max.nil?
    ids = (1..max).entries

    with_standard_pool(@size) do |pool|
      in_parallel(*ids) { |id| _config_load_one(pool, id, fs_type) }
      assert_equal(@size, PoolStatus.new(pool).free_data_sectors)
    end
  end

  def test_mass_create_apply_remove_with_config_load_ext4
    _mass_create_apply_remove_with_config_load(:ext4)
  end

  def test_mass_create_apply_remove_with_config_load_xfs
    _mass_create_apply_remove_with_config_load(:xfs)
  end
end

#----------------------------------------------------------------
