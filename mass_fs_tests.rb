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

  def setup
    super
  end

  tag :thinp_target, :slow

  #
  # bulk configuration followed by load
  #
  def _mass_create_apply_remove(fs_type, max = nil)
    max = 2 if max.nil?
    ids = Array.new
    thin_fs_list = Array.new
    0.upto(max) { |i| ids << i }

    with_standard_pool(@size) do |pool|
      ids.each { |i| pool.message(0, "create_thin #{i}") }

      with_thins(pool, @volume_size, *ids) do |*thins|
        in_parallel(*thins) do |thin|
          thin_fs_list << FS::file_system(fs_type, thin)
          thin_fs_list[-1].format
        end

        in_parallel(*thin_fs_list) { |thin_fs| thin_fs.check }
        ids.each { |i| thin_fs_list[i].with_mount("mnt#{i}") }
        dir = Dir.getwd

        in_parallel(*ids) do |id|
          Dir.chdir("#{dir}/mnt#{id}") do 
             ProcessControl.run("rsync -lr /usr/bin . > /dev/null"); 
          end
        end

        Dir.chdir("#{dir}")
        ids.each { |i| thin_fs_list[i].without_mount }
      end

      ids.each { |i| pool.message(0, "delete #{i}") }
      # assert_equal(@size, PoolStatus.new(pool).free_data_sectors)
    end
  end

  def test_mass_create_apply_remove_ext4
    _mass_create_apply_remove(:ext4)
  end

  def test_mass_create_apply_remove_xfs
    _mass_create_apply_remove(:xfs)
  end

  #
  # configuration changes under load
  #
  def _config_load_one(pool, id, fs_type)
    pool.message(0, "create_thin #{id}")

    with_thin(pool, @volume_size, id) do |thin|
      thin_fs = FS::file_system(fs_type, thin)
      thin_fs.format
      thin_fs.check
      thin_fs.with_mount("mnt#{id}")
      dt_device("mnt#{id}/tstfile")
      thin_fs.without_mount("mnt#{id}")
    end

    pool.message(0, "delete #{id}")
  end

  def _mass_create_apply_remove_with_config_load(fs_type, max = nil)
    max = 2 if max.nil?
    ids = Array.new
    0.upto(max) { |i| ids << i }

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
