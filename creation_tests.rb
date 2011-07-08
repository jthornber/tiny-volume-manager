require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'test/unit'

#----------------------------------------------------------------

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

  def test_create_lots_of_empty_thins
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      0.upto(1000) {|i| pool.message(0, "new-thin #{i}") }
    end
  end

  def test_create_lots_of_snaps
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      pool.message(0, "new-thin 0")
      1.upto(1000) {|i| pool.message(0, "new-snap #{i} 0") }
    end
  end

  def test_create_lots_of_recursive_snaps
    size = 20971520

    table = Table.new(ThinPool.new(size, @metadata_dev, @data_dev,
                                   @data_block_size, @low_water))

    @dm.with_dev(table) do |pool|
      pool.message(0, "new-thin 0")
      1.upto(1000) {|i| pool.message(0, "new-snap #{i} #{i - 1}") }
    end    
  end
end

#----------------------------------------------------------------
