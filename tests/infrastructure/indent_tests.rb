require 'lib/string/indent'

#----------------------------------------------------------------

class IndentTests < Test::Unit::TestCase
  EXPECTED =<<EOF
blah
    foo
        bar
    tttt
hux
EOF

  def test_indenter
    io = StringIO.new
    e = StringUtils::Emitter.new(io, 4)

    e.emit "blah"
    e.indent do
      e.emit "foo"
      e.indent do
        e.emit "bar"
        e.undent do
          e.emit 'tttt'
        end
      end
    end
    e.emit "hux"

    assert_equal(EXPECTED, io.string)
  end
end

#----------------------------------------------------------------
