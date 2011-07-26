require 'lib/process'

module Utils
  def wipe_device(dev_or_path)
    size = ProcessControl.system("102400", "blockdev --getsize #{dev_or_path}").chomp.to_i

    # We now want to calculate a reasonable block size and block count
    block_size = 2048 * 64       # 64 M
    count = size / block_size
    if count > 0
      ProcessControl.run("dd if=/dev/zero of=#{dev_or_path} oflag=direct bs=64M count=#{count}")
    end

    remainder = size % block_size
    if remainder != 0
      # we have a little bit to do at the end
      offset = block_size * (size / block_size)
      ProcessControl.run("dd if=/dev/zero of=#{dev_or_path} oflag=direct bs=#{remainder * 512} count=1 seek=#{offset * 512}")
    end
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
