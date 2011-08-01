require 'lib/log'
require 'lib/process'

#----------------------------------------------------------------

module FS
  class Ext4
    attr_accessor :dev

    def initialize(dev)
      @dev = dev
    end

    def format
      ProcessControl.run("mkfs.ext4 #{@dev}")
    end

    def with_mount(mount_point)
      ProcessControl.run("mount #{@dev} #{mount_point}")
      begin
        yield
      ensure
        ProcessControl.run("umount #{mount_point}")
        check
      end
    end

    def check
      ProcessControl.run("echo 1 > /proc/sys/vm/drop_caches");
      ProcessControl.run("fsck.ext4 -n #{@dev}")
    end
  end

  class XFS
    attr_accessor :dev

    def initialize(dev)
      @dev = dev
    end

    def format
      ProcessControl.run("mkfs.xfs -f #{@dev}")
    end

    def with_mount(mount_point)
      ProcessControl.run("mount -o nouuid #{@dev} #{mount_point}")
      begin
        yield
      ensure
        ProcessControl.run("umount #{mount_point}")
        check
      end
    end

    def check
      ProcessControl.run("echo 1 > /proc/sys/vm/drop_caches");
      ProcessControl.run("xfs_repair -n #{@dev}")
    end
  end

  def FS.file_system(type, dev)
    case type
    when :ext4
      Ext4.new(dev)
    when :xfs
      XFS.new(dev)
    else
      raise RuntimeError, "unknown fs type '#{type}'"
    end
  end
end

#----------------------------------------------------------------
