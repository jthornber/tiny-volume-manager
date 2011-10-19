require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/status'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/tvm'

#----------------------------------------------------------------

class ImmutableTargetTests < ThinpTestCase
  include Tags
  include TinyVolumeManager
  include Utils

  def setup
    super

    @tvm = VM.new
    @tvm.add_allocation_volume(@data_dev, 0, dev_size(@data_dev))
    @volume_size = dev_size(@data_dev) / 5
  end

  tag :dm_core, :quick, :thinp_target, :linear_target, :stripe_target

  # sanity check
  def test_linear_can_replace_linear
    @tvm.add_volume_('linear1', @volume_size)
    @tvm.add_volume_('linear2', @volume_size)

    with_dev(@tvm.table('linear1')) do |dev|
      dev.load(@tvm.table('linear2'))
      dev.resume
    end
  end

  def test_multiple_linear_can_replace_linear
    @tvm.add_volume_('linear1', @volume_size)
    @tvm.add_volume_('linear2', @volume_size)

    with_dev(@tvm.table('linear1')) do |dev|
      # get the segment for linear2 and break up into sub segments.
      segs = @tvm.segments('linear2')
      raise RuntimeError, "unexpected number of segments" if segs.size != 1

      seg = segs[0]
      l2 = seg.length / 2
      table = Table.new(Linear.new(l2, seg.dev, seg.offset),
                        Linear.new(seg.length - l2, seg.dev, seg.offset + l2))

      dev.load(table)
      dev.resume
    end
  end

  def test_pool_can_replace_linear
    @tvm.add_volume_('linear', @volume_size)
    @tvm.add_volume_('pool-data', @volume_size)

    with_devs(@tvm.table('linear'),
              @tvm.table('pool-data')) do |dev, data|

      dev.load(Table.new(ThinPool.new(@volume_size, @metadata_dev, data, 128, 0)))
      dev.resume
    end
  end

  def test_pool_must_be_singleton
    @tvm.add_volume_('metadata1', @volume_size)
    @tvm.add_volume_('metadata2', @volume_size)
    @tvm.add_volume_('data1', @volume_size)
    @tvm.add_volume_('data2', @volume_size)

    with_devs(@tvm.table('metadata1'),
              @tvm.table('metadata2'),
              @tvm.table('data1'),
              @tvm.table('data2')) do |md1, md2, d1, d2|

      wipe_device(md1, 8)
      wipe_device(md2, 8)

      assert_raises(RuntimeError) do
        with_dev(Table.new(ThinPool.new(@volume_size, md1, d1, 128, 0),
                           ThinPool.new(@volume_size, md2, d2, 128, 0))) do |bad_pool|
          # shouldn't get here
        end
      end
    end
  end

  def test_pool_must_be_singleton2
    @tvm.add_volume_('metadata', @volume_size)
    @tvm.add_volume_('data', @volume_size)
    @tvm.add_volume_('linear', @volume_size)

    with_devs(@tvm.table('metadata'),
              @tvm.table('data')) do |md, d, linear|

      wipe_device(md, 8)
      assert_raises(RuntimeError) do
        with_dev(Table.new(ThinPool.new(@volume_size, md, d, 128, 0),
                           *@tvm.table('linear').targets)) do |bad_pool|
          # shouldn't get here
        end
      end
    end
  end

  def test_same_pool_can_replace_pool
    @tvm.add_volume_('md', @volume_size)
    @tvm.add_volume_('data', @volume_size)

    with_devs(@tvm.table('md'),
              @tvm.table('data')) do |md, data|

      wipe_device(md, 8)
      table = Table.new(ThinPool.new(@volume_size, md, data, 128, 0))
      
      with_dev(table) do |pool|
        pool.load(table)
        pool.resume
      end
    end
  end

  def test_different_pool_cant_replace_pool
    @tvm.add_volume_('metadata1', @volume_size)
    @tvm.add_volume_('metadata2', @volume_size)
    @tvm.add_volume_('data1', @volume_size)
    @tvm.add_volume_('data2', @volume_size)

    with_devs(@tvm.table('metadata1'),
              @tvm.table('metadata2'),
              @tvm.table('data1'),
              @tvm.table('data2')) do |md1, md2, d1, d2|

      wipe_device(md1, 8)
      wipe_device(md2, 8)

      with_dev(Table.new(ThinPool.new(@volume_size, md1, d1, 128, 0))) do |pool|
        assert_raises(RuntimeError) do
          pool.load(Table.new(ThinPool.new(@volume_size, md2, d2, 128, 0)))
          pool.resume
        end
      end
    end
  end

  def test_pool_replacement_must_be_singleton
    @tvm.add_volume_('md', @volume_size)
    @tvm.add_volume_('data', @volume_size)
    @tvm.add_volume_('linear', @volume_size)

    with_devs(@tvm.table('md'),
              @tvm.table('data')) do |md, data|

      wipe_device(md, 8)
      table = Table.new(ThinPool.new(@volume_size, md, data, 128, 0))
      
      with_dev(table) do |pool|
        seg = @tvm.segments('linear')[0]
        table = Table.new(ThinPool.new(@volume_size, md, data, 128, 0),
                          Linear.new(@volume_size, seg.dev, seg.offset))
        assert_raises(RuntimeError) do
          pool.load(table)
        end
      end
    end
    
  end

  def test_pool_replace_cant_be_linear
    @tvm.add_volume_('md', @volume_size)
    @tvm.add_volume_('data', @volume_size)
    @tvm.add_volume_('linear', @volume_size)

    with_devs(@tvm.table('md'),
              @tvm.table('data')) do |md, data|

      wipe_device(md, 8)
      table = Table.new(ThinPool.new(@volume_size, md, data, 128, 0))
      
      with_dev(table) do |pool|
        assert_raises(RuntimeError) do
          pool.load(@tvm.table('linear'))
        end
      end
    end
  end
end

#----------------------------------------------------------------
