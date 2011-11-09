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

  def test_kernel_can_use_restored_volume
    # fully provision a dev
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @volume_size, 0) {|thin| wipe_device(thin)}
    end
    
    dump_metadata(@metadata_dev) do |xml_path1|
      wipe_device(@metadata_dev)
      restore_metadata(xml_path1, @metadata_dev)
      
      with_standard_pool(@size) do |pool|
        with_thin(pool, @volume_size, 0) {|thin| wipe_device(thin)}
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
