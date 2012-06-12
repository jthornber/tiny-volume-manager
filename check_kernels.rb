require 'config'
require 'lib/log'
require 'lib/dm'
require 'lib/process'
require 'lib/fs'
require 'lib/utils'

#----------------------------------------------------------------

include Utils

SIZE = 20971520

def fsck_linux(dm, pool, dev_id)
  thin_table = Table.new(ThinTarget.new(SIZE / 4, pool, dev_id))

  dm.with_dev(thin_table) do |thin|
    thin_fs = FS::file_system(:ext4, thin)
    thin_fs.check

    mnt = "./mnt#{dev_id}"
    thin_fs.with_mount(mnt) do
      ProcessControl.run("diff -ruNq linux-2.6.39.3 #{mnt}/linux-2.6.39.3")
    end

  end
end

config = Config.get_config
metadata_dev = config[:metadata_dev]
data_dev = config[:data_dev]

data_block_size = 128
low_water_mark = 1024
dm = DMInterface.new

table = Table.new(ThinPoolTarget.new(SIZE, metadata_dev, data_dev,
                                     data_block_size, low_water_mark))

dm.with_dev(table) do |pool|
  0.upto(3) do |dev_id|
    puts "checking #{dev_id}"
    fsck_linux(dm, pool, dev_id)
  end
end


#----------------------------------------------------------------
