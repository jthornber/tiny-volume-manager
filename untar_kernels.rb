require 'config'
require 'lib/log'
require 'lib/dm'
require 'lib/process'
require 'lib/fs'
require 'lib/utils'

#----------------------------------------------------------------

include Utils

SIZE = 20971520

def extract_linux(dm, pool, dev_id)
  thin_table = Table.new(Thin.new(SIZE / 4, pool, dev_id))

  dm.with_dev(thin_table) do |thin|
    thin_fs = FS::file_system(:ext4, thin)
    thin_fs.format
    thin_fs.with_mount("./mnt#{dev_id}") do
      Dir.chdir("mnt#{dev_id}") do
        ProcessControl.run("tar jxvf /root/linux-2.6.39.3.tar.bz2 > /dev/null");  
      end
    end
  end
end

config = Config.get_config
metadata_dev = config[:metadata_dev]
data_dev = config[:data_dev]

data_block_size = 128
low_water_mark = 1024
dm = DMInterface.new

wipe_device(metadata_dev, 8)

table = Table.new(ThinPool.new(SIZE, metadata_dev, data_dev,
                               data_block_size, low_water_mark))

dm.with_dev(table) do |pool|
  0.upto(3) do |dev_id|
    puts "extracting #{dev_id}"
    pool.message(0, "create_thin #{dev_id}")
    extract_linux(dm, pool, dev_id)
  end
end


#----------------------------------------------------------------
