require 'config'
require 'lib/git'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/blktrace'
require 'pp'

#----------------------------------------------------------------

class FakeDiscardTests < ThinpTestCase
  include Tags
  include Utils
  include BlkTrace

  def setup
    super
  end

  def assert_not_supported(opts)
    with_fake_discard(opts) do |dev|
      assert_raise(Errno::EOPNOTSUPP) do
        dev.discard(0, @data_block_size)
      end
    end
  end

  def assert_discard(traces, start_sector, length)
      assert(traces[0].member?(Event.new([:discard], start_sector, length)))
  end

  def test_disable_discard
    assert_not_supported(:discard_support => false)
  end

  def test_enable_discard
    with_fake_discard do |dev|
      traces, _ = blktrace(dev) do
        dev.discard(0, @data_block_size)
      end

      assert_discard(traces, 0, @data_block_size)
    end
  end

  def test_granularity
    [64, 128, 1024].each do |gran|
      with_fake_discard(:granularity => gran, :max_discard_sectors => 128 * gran) do |dev|
        traces, _ = blktrace(dev) do
          dev.discard(0, gran * 3)
        end

        assert_discard(traces, 0, gran * 3)

        traces, _ = blktrace(dev) do
          dev.discard(gran - 1, gran * 3)
        end

        pp traces
        assert_discard(traces, gran, gran * 2)
      end

      
    end
  end
end
