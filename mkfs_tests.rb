require 'config'
require 'lib/dm'
require 'lib/fs'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class MkfsTests < ThinpTestCase
  include Tags
  include Utils

  def setup
    super
    @volume_size = @size / 4 if @volume_size.nil?
  end

  def do_mkfs_test(fs_type)
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @size, 0) do |thin|
        thin_fs = FS::file_system(fs_type, thin)
        thin_fs.format
        thin_fs.check
      end
    end
  end

  def test_mkfs_ext4
    do_mkfs_test(:ext4)
  end

  def test_mkfs_xfs
    do_mkfs_test(:xfs)
  end
end

#----------------------------------------------------------------
