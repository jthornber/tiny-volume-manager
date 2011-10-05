require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/status'
require 'lib/utils'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/tvm'

#----------------------------------------------------------------

class MassFsTests < ThinpTestCase
  include Tags
  include TinyVolumeManager
  include Utils

  def report_time(desc, &block)
    elapsed = time_block(&block)
    info "Elapsed #{elapsed}: #{desc}"
  end

  # format, fsck, mount, copy, umount, fsck
  def fs_cycle(dev, fs_type, mount_point)
    fs = FS::file_system(fs_type, dev)
    report_time('formatting') {fs.format}
    report_time('fsck') {fs.check}
    report_time('mount + rsync + umount + fsck') do
      fs.with_mount(mount_point) do
        report_time('rsync') do
          ProcessControl.run("rsync -lr /usr/bin #{mount_point} > /dev/null; sync")
        end
      end
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
          mount_point = "#{dir}/mnt_#{thin.name}"
          fs_cycle(thin, fs_type, mount_point)
        end
      end

      ids.each { |i| pool.message(0, "delete #{i}") }
      assert_equal(@size, PoolStatus.new(pool).free_data_sectors)
    end
  end

  def _mass_linear_create_apply_remove(fs_type, max)
    tvm = VM.new
    tvm.add_allocation_volume(@data_dev, 0, dev_size(@data_dev))

    size = tvm.free_space / max
    names = Array.new
    1.upto(max) do |i|
      name = "linear-#{i}"
      tvm.add_volume(VolumeDescription.new(name, size))
      names << name
    end

    with_devs(names.map {|n| tvm.table(n)}) do |devs|
      in_parallel(*devs) do |dev|
        mount_point = "#{dir}/mnt_#{thin.name}"
        fs_cycle(dev, fs_type, mount_point)
      end
    end
  end

  tag :linear_target, :slow

  def test_mass_linear_create_apply_remove_ext4
    _mass_linear_create_apply_remove(:ext4, 4)
  end

  def test_mass_linear_create_apply_remove_xfs
    _mass_linear_create_apply_remove(:xfs, 4)
  end

  tag :thinp_target, :slow

  def test_mass_create_apply_remove_ext4
    _mass_create_apply_remove(:ext4, 4)
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
