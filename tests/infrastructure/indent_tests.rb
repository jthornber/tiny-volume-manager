require 'lib/string/indent'

#----------------------------------------------------------------

class IndentTests < Test::Unit::TestCase
  EXPECTED =<<EOF
blah
    foo
        bar
hux
EOF

  def test_indenter
    io = StringIO.new
    e = StringUtils::Emitter.new(io, 4)

    e.emit "blah"
    e.indent do
      e.emit "foo"
      e.indent {e.emit "bar"}
    end
    e.emit "hux"

    assert_equal(EXPECTED, io.string)
  end
end

#----------------------------------------------------------------
