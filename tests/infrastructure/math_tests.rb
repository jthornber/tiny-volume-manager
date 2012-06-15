require 'lib/math-utils'
require 'lib/tags'

#----------------------------------------------------------------

class MathUtilsTests < Test::Unit::TestCase
  include Tags
  include MathUtils

  tag :quick, :infrastructure

  def test_round_up
    assert_equal(6, round_up(5, 3))
    assert_equal(3, round_up(3, 3))
  end

  def test_round_down
    assert_equal(6, round_down(6, 3))
    assert_equal(3, round_down(5, 3))
  end

  def test_div_up
    assert_equal(2, div_up(5, 3))
    assert_equal(1, div_up(3, 3))
  end
end

#----------------------------------------------------------------
