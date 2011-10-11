require 'lib/log'
require 'lib/process'

#----------------------------------------------------------------

module FS
  class BaseFS
    attr_accessor :dev, :mount_point

    def initialize(dev)
      @dev = dev
      @mount_point = nil
    end

    def format
      ProcessControl.run(mkfs_cmd)
    end

    def mount(mount_point)
      @mount_point = mount_point
      Pathname.new(mount_point).mkpath
      ProcessControl.run(mount_cmd(mount_point))
    end

    def umount
      ProcessControl.run("umount #{@mount_point}")
      Pathname.new(@mount_point).delete
      @mount_point = nil
      check
    end

    def with_mount(mount_point, &block)
      mount(mount_point)
      bracket_(lambda {umount}, &block)
    end

    def check
      ProcessControl.run("echo 1 > /proc/sys/vm/drop_caches");
      ProcessControl.run(check_cmd)
    end
  end

  class Ext4 < BaseFS
    def mount_cmd(mount_point); "mount #{dev} #{mount_point}"; end
    def check_cmd; "fsck.ext4 -fn #{dev}"; end
    def mkfs_cmd; "mkfs.ext4 #{dev}"; end
  end

  class XFS < BaseFS
    def mount_cmd(mount_point); "mount -o nouuid #{dev} #{mount_point}"; end
    def check_cmd; "xfs_repair -n #{dev}"; end
    def mkfs_cmd; "mkfs.xfs -f #{dev}"; end
  end

  FS_CLASSES = {
    :ext4 => Ext4,
    :xfs => XFS
  }

  def FS.file_system(type, dev)
    unless FS_CLASSES.member?(type)
      raise RuntimError, "unknown filesystem type '#{type}'"
    end

    FS_CLASSES[type].new(dev)
  end
end

#----------------------------------------------------------------
