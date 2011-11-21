require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/xml_format'

#----------------------------------------------------------------

class RestoreTests < ThinpTestCase
  include Tags
  include Utils
  include XMLFormat

  def setup
    super
  end

  tag :thinp_target
  tag :thinp_target, :slow

  # FIXME: move to thinp-test
  def assert_identical_files(f1, f2)
    begin
      ProcessControl::run("diff #{f1} #{f2}")
    rescue
      flunk("files differ #{f1} #{f2}")
    end
  end

  # Reads the metadata from an _inactive_ pool
  # FIXME: move to thinp-test.rb ?
  def dump_metadata(dev)
    metadata = nil
    Utils::with_temp_file('metadata_xml') do |file|
      ProcessControl::run("thin_dump -i #{dev} > #{file.path}")
      file.rewind
      yield(file.path)
    end
  end

  def restore_metadata(xml_path, dev)
    ProcessControl::run("thin_restore -i #{xml_path} -o #{dev}")
  end

  # Uses io to prepare a simple metadata dev
  # FIXME: we need snapshots, and multiple thins in here
  def prepare_md
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) {|thin| dt_device(thin)}
    end
  end

  def test_dump_is_idempotent
    prepare_md

    dump_metadata(@metadata_dev) do |xml_path1|
      dump_metadata(@metadata_dev) do |xml_path2|
        assert_identical_files(xml_path1, xml_path2)
      end
    end
  end

  def test_dump_restore_dump_is_idempotent
    prepare_md

    dump_metadata(@metadata_dev) do |xml_path1|
      wipe_device(@metadata_dev)
      restore_metadata(xml_path1, @metadata_dev)

      dump_metadata(@metadata_dev) do |xml_path2|
        assert_identical_files(xml_path1, xml_path2);
      end
    end
  end

  def create_linear_metadata(dev_count, dev_size)
    superblock = Superblock.new("uuid here", 0, 1, 128)

    devices = Array.new
    offset = 0
    0.upto(dev_count - 1) do |dev|
      nr_mappings = dev_size
      mappings = Array.new
      1.upto(nr_mappings) {|n| mappings << Mapping.new(n, offset + n, 1, 1)}
      devices << Device.new(dev, nr_mappings, 0, 0, 0, mappings)

      offset += nr_mappings
    end

    Metadata.new(superblock, devices)
  end

  def linear_array(len)
    ary = Array.new
    (0..(len - 1)).each {|n| ary[n] = n}
    ary
  end

  def shuffled_array(len)
    ary = linear_array(len)

    (0..(len - 1)).each do |n|
      n2 = n + rand(len - n)
      tmp = ary[n]
      ary[n] = ary[n2]
      ary[n2] = tmp
    end

    ary
  end

  def create_metadata(dev_count, dev_size, block_mapper)
    superblock = Superblock.new("uuid here", 0, 1, 128)

    devices = Array.new
    offset = 0
    dest_blocks = self.send(block_mapper, dev_size * dev_count)

    0.upto(dev_count - 1) do |dev|
      nr_mappings = dev_size
      mappings = Array.new
      0.upto(nr_mappings - 1) do |n|
        mappings << Mapping.new(n, dest_blocks[offset + n], 1, 1)
      end
      devices << Device.new(dev, nr_mappings, 0, 0, 0, mappings)

      offset += nr_mappings
    end

    Metadata.new(superblock, devices)
  end

  def restore_mappings(nr_devs, dev_size, mapper)
    # We don't use the kernel for this test, instead just creating a
    # large complicated xml metadata file, and then restoring it.
    metadata = create_metadata(nr_devs, dev_size, mapper)

    Utils::with_temp_file('metadata_xml') do |file|
      write_xml(metadata, file)
      file.flush
      file.close
      restore_metadata(file.path, @metadata_dev)
    end

    ProcessControl.run("thin_repair #{@metadata_dev}")
    metadata
  end

  def do_kernel_happy_test(allocator)
    n = 1000

    restore_mappings(4, n, allocator)
    dump_metadata(@metadata_dev) do |xml1|
      with_standard_pool(@size) do |pool|
        with_thin(pool, n * 128, 0) {|thin| wipe_device(thin)}
      end

      # These devices were fully provisioned, so we check the mapping is
      # identical after the wipe.
      dump_metadata(@metadata_dev) do |xml2|
        assert_identical_files(xml1, xml2);
      end
    end
  end

  def test_kernel_happy_with_linear_restored_data
    do_kernel_happy_test(:linear_array)
  end

  def test_kernel_happy_with_random_restored_data
    do_kernel_happy_test(:shuffled_array)
  end

  def test_kernel_can_use_restored_volume
    # fully provision a dev
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) {|thin| wipe_device(thin)}
    end
    
    dump_metadata(@metadata_dev) do |xml_path1|
      wipe_device(@metadata_dev)
      restore_metadata(xml_path1, @metadata_dev)
      
      with_standard_pool(@size) do |pool|
        with_thin(pool, @volume_size, 0) {|thin| wipe_device(thin, 1000)}
      end

      # metadata shouldn't have changed, since thin was fully
      # provisioned.
      dump_metadata(@metadata_dev) do |xml_path2|
        assert_identical_files(xml_path1, xml_path2)
      end
    end
  end
end

#----------------------------------------------------------------
