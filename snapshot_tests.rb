require 'config'
require 'lib/dm'
require 'lib/fs'
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

class SnapshotTests < Test::Unit::TestCase
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

  def do_create_snap(fs_type)
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      pool.message(0, 'create_thin 0')

      @dm.with_dev(Table.new(Thin.new(size, pool, 0))) do |thin|
        thin_fs = FS::file_system(fs_type, thin)
        thin_fs.format
        thin_fs.with_mount("./mnt1") do
          ds = Dataset.read('compile-bench-datasets/dataset-unpatched')
          Dir.chdir('mnt1') { ds.apply(1000) }

          thin.suspend
          pool.message(0, 'create_snap 1 0')
          thin.resume

          @dm.with_dev(Table.new(Thin.new(size, pool, 1))) do |snap|
            snap_fs = FS::file_system(fs_type, snap)
            snap_fs.with_mount("./mnt2") do
              ds = Dataset.read('compile-bench-datasets/dataset-unpatched-compiled')
              Dir.chdir('mnt2') { ds.apply(1000) }
            end
          end
        end
      end
    end
  end

  def do_break_sharing(fs_type)
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      pool.message(0, 'create_thin 0')

      @dm.with_dev(Table.new(Thin.new(size, pool, 0))) do |thin|
        thin_fs = FS::file_system(fs_type, thin)
        thin_fs.format

        t = time_block do
          thin_fs.with_mount("./mnt1") do
            ds = Dataset.read('compile-bench-datasets/dataset-unpatched')
            Dir.chdir('mnt1') { ds.apply(1000) }
          end
        end
        info "writing first dataset took #{t} seconds"
      end

      pool.message(0, 'create_snap 1 0')

      @dm.with_dev(Table.new(Thin.new(size, pool, 1))) do |snap|
        snap_fs = FS::file_system(fs_type, snap)
        t = time_block do
          snap_fs.with_mount("./mnt2") do
            ds = Dataset.read('compile-bench-datasets/dataset-unpatched-compiled')
            Dir.chdir('mnt2') { ds.apply(1000) }
          end
        end
        info "writing second dataset took #{t} seconds"
      end
    end
  end

  def time_block
    start_time = Time.now 
    yield 
    return Time.now - start_time 
  end

  def do_overwrite(fs_type)
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water, false))

    @dm.with_dev(table) do |pool|
      pool.message(0, 'create_thin 0')

      @dm.with_dev(Table.new(Thin.new(size, pool, 0))) do |thin|
        thin_fs = FS::file_system(fs_type, thin)

        t_format = time_block do
          thin_fs.format
        end
        info "formatting took #{t_format} seconds"

        ds = Dataset.read('compile-bench-datasets/dataset-unpatched')
        t = time_block do
          thin_fs.with_mount("./mnt1") do
            Dir.chdir('mnt1') { ds.apply(1000) }
          end
        end
        info "writing first dataset took #{t} seconds"

        t = time_block do
        thin_fs.with_mount("./mnt1") do
            Dir.chdir('mnt1') { ds.apply(1000) }
          end
        end
        info "writing second dataset took #{t} seconds"
      end
    end
  end

  def test_thin_overwrite_ext4
    do_overwrite(:ext4)
  end

  def test_thin_overwrite_xfs
    do_overwrite(:xfs)
  end

  def test_create_snap_ext4
    do_create_snap(:ext4)
  end

  def test_create_snap_xfs
    do_create_snap(:xfs)
  end

  def test_break_sharing_xfs
    do_break_sharing(:xfs)
  end

  def test_break_sharing_ext4
    do_break_sharing(:ext4)
  end
end

#----------------------------------------------------------------
