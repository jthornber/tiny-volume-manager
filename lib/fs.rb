require 'lib/log'
require 'lib/process'

#----------------------------------------------------------------

module FS
  class AnyFS
    attr_accessor :dev, :mount_point

    def initialize(type, dev)
      @dev = dev
      @mount_point = nil

      case type
      when :ext4
        @fsck = "fsck.ext4 -fn"
        @mkfs = "mkfs.ext4"
      when :xfs
        @fsck = "xfs_repair -n"
        @mkfs = "mkfs.xfs -f"
      else
        raise RuntimeError, "unknown fs type '#{type}'"
      end
    end

    def format
      ProcessControl.run("#{@mkfs} #{@dev}")
    end

    def mount(mount_point)
      @mount_point = mount_point
      Pathname.new(mount_point).mkpath
      ProcessControl.run("mount #{@dev} #{mount_point}")
    end

    def umount
      ProcessControl.run("umount #{@mount_point}")
      @mount_point = nil
      check
    end

    def with_mount(mount_point, &block)
      mount(mount_point)
      bracket_(lambda {umount}, &block)
    end

    def check
      ProcessControl.run("echo 1 > /proc/sys/vm/drop_caches");
      ProcessControl.run("#{@fsck} #{@dev}")
    end
  end

  def FS.file_system(type, dev)
    AnyFS.new(type, dev)
  end
end

#----------------------------------------------------------------
