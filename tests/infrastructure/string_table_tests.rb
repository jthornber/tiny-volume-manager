require 'lib/string/string-table'

#----------------------------------------------------------------

class StringTableTests < Test::Unit::TestCase
  include StringUtils

  def test_string_table
    t = StringTable.new

    t.add("one")
    t.add("two")
    t.add("three")

    results = Array.new
    t.each do |k, v|
      results << [k, v]
    end

    assert_equal([["one", 0], ["three", 2], ["two", 1]], results.sort)

    assert_raise(RuntimeError) do
      t["not present"]
    end

    assert_equal(0, t["one"])
  end
end

#----------------------------------------------------------------
