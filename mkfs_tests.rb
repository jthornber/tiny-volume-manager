require 'config'
require 'lib/fs'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class MkfsTests < ThinpTestCase
  include Tags
  include TinyVolumeManager
  include Utils

  def setup
    super
    @volume_size = @size / 4 if @volume_size.nil?
  end

  def mkfs(dev, fs_type)
    thin_fs = FS::file_system(fs_type, dev)
    report_time("formatting #{fs_type} file system") {thin_fs.format}
    thin_fs.check
  end

  def mkfs_thin(fs_type)
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @size, 0) do |thin|
        mkfs(thin, fs_type)
      end

      status = PoolStatus.new(pool)
      STDERR.puts "pool allocated #{status.used_data_blocks} data blocks"
    end
  end

  def mkfs_linear(fs_type)
    tvm = VM.new
    tvm.add_allocation_volume(@data_dev, 0, dev_size(@data_dev))
    tvm.add_volume(linear_vol('linear', @size))
    with_dev(tvm.table('linear')) do |dev|
      mkfs(dev, fs_type)
    end
  end

  def test_mkfs_ext4
    mkfs_linear(:ext4)
    mkfs_thin(:ext4)
  end

  def test_mkfs_xfs
    mkfs_linear(:xfs)
    mkfs_thin(:xfs)
  end
end

#----------------------------------------------------------------
