require 'config'
require 'lib/device-mapper/dm'
require 'lib/dataset'
require 'lib/fs'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/disk-units'
require 'lib/utils'

#----------------------------------------------------------------

class StripesOnThinStack
  include DM
  include DMThinUtils
  include Utils

  def initialize(dm, data_dev, metadata_dev, nr_stripes, chunk_size, stripe_width)
    @dm = dm
    @data_dev = data_dev
    @metadata_dev = metadata_dev
    @nr_stripes = nr_stripes
    @chunk_size = chunk_size
    @stripe_width = stripe_width
  end

  def activate(&block)
    pool_table = Table.new(ThinPoolTarget.new(dev_size(@data_dev),
                                              @metadata_dev,
                                              @data_dev,
                                              128,
                                              0,
                                              true,
                                              true,
                                              false))

    # format the metadata dev
    wipe_device(@metadata_dev, 8)

    @dm.with_dev(pool_table) do |pool|
      ids = (0..(@nr_stripes - 1)).to_a
      with_new_thins(pool, @stripe_width, *ids) do |*stripes|
        stripe_pairs = stripes.map {|dev| [dev, 0]}
        stripe_table = Table.new(StripeTarget.new(@stripe_width * @nr_stripes,
                                                  @nr_stripes,
                                                  @chunk_size,
                                                  stripe_pairs))
        @dm.with_dev(stripe_table) do |striped|
          block.call(striped)
        end
      end
    end
  end
end

#----------------------------------------------------------------

class StripedTests < ThinpTestCase
  include Tags
  include Utils
  include DiskUnits

  def do_striped_on_thin(nr_stripes, fs_type)
    stack = StripesOnThinStack.new(@dm, @data_dev, @metadata_dev, nr_stripes, 512, gig(10))
    stack.activate do |striped|
      fs = FS::file_system(fs_type, striped)
      fs.format
      fs.with_mount("./striped_mount") {} # forces a fsck
    end
  end

  2.upto(5) do |nr_stripes|
    [:ext4, :xfs].each do |fs_type|
      method_name = "test_#{nr_stripes}_stripes_on_thin_#{fs_type}".intern
      define_method(method_name) do
        do_striped_on_thin(nr_stripes, fs_type)
      end
    end
  end
end

#----------------------------------------------------------------
