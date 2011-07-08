require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'test/unit'

# these added for the dataset stuff
require 'fileutils'

#----------------------------------------------------------------

class DatasetFile < Struct.new(:path, :size)
end

class Dataset
  attr_accessor :files

  def initialize(files)
    @files = files
  end

  def apply(count = nil)
    if count.nil? || count >= @files.size
      files.each do |f|
        create_file(f.path, f.size)
      end
    else
      0.upto(count) do |i|
        f = @files[i]
        create_file(f.path, f.size)
      end
    end
  end

  def Dataset.read(path)
    files = Array.new

    File.open(path) do |file|
      while line = file.gets
        m = line.match(/(\S+)\s(\d+)/)
        unless m.nil?
          files << DatasetFile.new(m[1], m[2].to_i)
        end
      end
    end

    Dataset.new(files)
  end

  private
  def breakup_path(path)
    elements = path.split('/')
    return [elements[0..elements.size - 2].join('/'), elements[elements.size - 1]]
  end

  def in_directory(dir)
    FileUtils.makedirs(dir)
    Dir.chdir(dir) do
      yield
    end
  end

  def create_file(path, size)
    dir, name = breakup_path(path)

    in_directory(dir) do
      File.open(name, "wb") do |file|
        file.syswrite('-' * size)
      end
    end
  end
end

class CreationTests < Test::Unit::TestCase
  include Utils

  def setup
    config = Config.get_config
    @metadata_dev = config[:metadata_dev]
    @data_dev = config[:data_dev]

    @data_block_size = 128
    @low_water = 1024
    @dm = DMInterface.new

    wipe_device(@metadata_dev)
  end

  def teardown
  end

  def test_create_snap
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|

      # totally provision a thin device
      pool.message(0, 'new-thin 0')
      @dm.with_dev(Table.new(Thin.new(size, pool, 0))) do |thin|
        ProcessControl.run("mkfs.ext4 #{thin.path}")
        ProcessControl.run("mount #{thin.path} ./mnt1")
        begin
          ds = Dataset.read('compile-bench-datasets/dataset-unpatched')
          Dir.chdir('mnt1') { ds.apply(1000) }

          thin.suspend
          pool.message(0, 'new-snap 1 0')
          thin.resume

          @dm.with_dev(Table.new(Thin.new(size, pool, 1))) do |snap|
            #ProcessControl.run("xfs_admin -U generate #{snap.path}")
            ProcessControl.run("mount #{snap.path} ./mnt2")
            begin
              ds = Dataset.read('compile-bench-datasets/dataset-unpatched-compiled')
              Dir.chdir('mnt2') { ds.apply(1000) }
            ensure
              ProcessControl.run("umount ./mnt2")
            end
            ProcessControl.run("fsck.ext4 -n #{snap.path}")
          end

        ensure
          ProcessControl.run("umount ./mnt1")
        end
        ProcessControl.run("fsck.ext4 -n #{thin.path}")
      end
    end
  end
end

#----------------------------------------------------------------
