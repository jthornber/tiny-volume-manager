require 'lib/process'

module Utils
  def wipe_device(dev_or_path, sectors = nil)
    dev_size = ProcessControl.system("102400", "blockdev --getsize #{dev_or_path}").chomp.to_i

    if sectors.nil? || dev_size < sectors
      sectors = dev_size
    end

    block_size = 2048 * 64       # 64 M
    count = sectors / block_size
    if count > 0
      ProcessControl.run("dd if=/dev/zero of=#{dev_or_path} oflag=direct bs=#{block_size * 512} count=#{count}")
    end

    remainder = sectors % block_size
    if remainder > 0
      # we have a little bit to do at the end
      offset = count * block_size
      ProcessControl.run("dd if=/dev/zero of=#{dev_or_path} oflag=direct bs=#{remainder * 512} count=1 seek=#{offset * 512}")
    end
  end

  def dt_device(dev)
    ProcessControl.run("dt of=#{dev} pattern=iot passes=1")
  end

  def get_dev_code(path)
    stat = File.stat(path)
    if stat.blockdev?
      "#{stat.rdev_major}:#{stat.rdev_minor}"
    else
      path
    end
  end
end

