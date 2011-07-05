require 'lib/process'

module Utils
  def wipe_device(dev_or_path)
    ProcessControl.run("dd if=/dev/zero of=#{dev_or_path} oflag=direct bs=16M")
  end
end
