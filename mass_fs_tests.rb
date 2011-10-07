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
    report_time('mount + rsync + umount') do
      fs.with_mount(mount_point) do
        report_time('rsync') do
          ProcessControl.run("rsync -lr /usr/bin #{mount_point} > /dev/null; sync")
        end
      end
    end

    report_time('fsck after rsync+umount') {fs.check}
  end

  #
  # bulk configuration followed by load
  #
  def _mass_create_apply_remove(fs_type, max)
    ids = (1..max).entries
    size = dev_size(@data_dev) / max

    with_standard_pool(@size, :zero => false) do |pool|
      with_new_thins(pool, size, *ids) do |*thins|
        in_parallel(*thins) {|thin| fs_cycle(thin, fs_type, "mnt_#{thin.name}") }
      end

      ids.each { |id| pool.message(0, "delete #{id}") }
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

    with_devs(*(names.map {|n| tvm.table(n)})) do |*devs|
      in_parallel(*devs) {|dev| fs_cycle(dev, fs_type, "mnt_#{dev.name}")}
    end
  end

  tag :linear_target, :slow

  def test_mass_linear_create_apply_remove_ext4
    _mass_linear_create_apply_remove(:ext4, 128)
  end

  def test_mass_linear_create_apply_remove_xfs
    _mass_linear_create_apply_remove(:xfs, 128)
  end

  tag :thinp_target, :slow

  def test_mass_create_apply_remove_ext4
    _mass_create_apply_remove(:ext4, 128)
  end

  def test_mass_create_apply_remove_xfs
    _mass_create_apply_remove(:xfs, 128)
  end

  #
  # configuration changes under load
  #
  def _config_load_one(pool, id, fs_type)
    pool.message(0, "create_thin #{id}")
    with_thin(pool, @volume_size, id) { |thin| fs_cycle(thin, fs_type, "mnt_#{thin.name}") }
    pool.message(0, "delete #{id}")
  end

  def _mass_create_apply_remove_with_config_load(fs_type, max = nil)
    max = 128 if max.nil?
    ids = (1..max).entries

    with_standard_pool(@size, :zero => false) do |pool|
      in_parallel(*ids) {|id| _config_load_one(pool, id, fs_type)}
      assert_equal(@size, PoolStatus.new(pool).free_data_sectors)
    end
  end

  def test_mass_create_apply_remove_with_config_load_ext4
    _mass_create_apply_remove_with_config_load(:ext4, 128)
  end

  def test_mass_create_apply_remove_with_config_load_xfs
    _mass_create_apply_remove_with_config_load(:xfs, 128)
  end
end

#----------------------------------------------------------------
