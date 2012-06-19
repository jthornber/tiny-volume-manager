require 'lib/device-mapper/ll_instr'
require 'lib/tags'

#----------------------------------------------------------------

class LLInstrTests < Test::Unit::TestCase
  include DM::LowLevel
  include Tags

  tag :quick, :infrastructure

  def test_instruction
    i = Instruction.new(:blip, 1, 2, 3, 4)
    assert_equal(:blip, i.op)
    assert_equal(1, i[0])
    assert_equal(2, i[1])
    assert_equal([1, 2, 3, 4], i.args)

    args = Array.new
    i.each do |n|
      args << n
    end

    assert_equal([1, 2, 3, 4], args)
  end
end

#----------------------------------------------------------------
