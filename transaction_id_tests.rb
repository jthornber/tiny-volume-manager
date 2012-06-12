require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/process'
require 'lib/utils'
require 'lib/status'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class TransactionIdTests < ThinpTestCase
  include Tags
  include Utils

  def trans_id(pool)
    PoolStatus.new(pool).transaction_id
  end

  def test_initial_trans_id_is_zero
    with_standard_pool(@size) do |pool|
      assert_equal 0, trans_id(pool)
    end
  end

  def test_set_trans_id_works
    with_standard_pool(@size) do |pool|
      0.upto(1000) do |n|
        set_trans_id(pool, n, n + 1)
      end
    end
  end

  def test_set_trans_id_check_first_arg
    with_standard_pool(@size) do |pool|
      assert_raise(ExitError) do
        set_trans_id(pool, 500, 1000)
      end

      assert_raise(ExitError) do
        set_trans_id(pool, 500, 0)
      end

      set_trans_id(pool, 0, 1234)

      assert_raise(ExitError) do
        set_trans_id(pool, 0, 1234)
      end

      set_trans_id(pool, 1234, 0)

      assert_raise(ExitError) do
        set_trans_id(pool, 1234, 0)
      end

      set_trans_id(pool, 0, 1234)
    end
  end
end

#----------------------------------------------------------------
