
# Combinator library for parsing arrays of objects
module ArrayParser

  class ArrayParserError < StandardError
  end

  module Detail
    class ParseSuccess < Struct.new(:value, :remaining_input)
      def success?
        true
      end
    end

    class ParseFail < Struct.new(:msg)
      def success?
        false
      end
    end

    class ArrayParser
      def success(value, rest)
        ParseSuccess.new(value, rest)
      end

      def failure(msg)
        ParseFail.new(msg)
      end

      def parse(array)
        parse_(get_input(array))
      end

      private
      def get_input(array)
        array.to_a
      rescue => e
        raise ArrayParserError, "not an array (or cannot be converted to one"
      end
    end

    class Fail < ArrayParser
      def initialize(msg)
        @msg = msg
      end

      def parse_(_)
        failure(@msg)
      end
    end

    class Success < ArrayParser
      def initialize(value)
        @value = value
      end

      def parse_(args)
        success(@value, args)
      end
    end

    #--------------------------------

    class Literal < ArrayParser
      def initialize(lit)
        @lit = lit
      end

      def parse_(input)
        if input.size >= 1 && input[0] == @lit
          success(nil, input[1..(input.size - 1)])
        else
          failure("couldn't match literal '#{@lit}'")
        end
      end
    end

    #--------------------------------

    class Choice < ArrayParser
      def initialize(*parsers)
        @parsers = parsers
      end

      def parse_(input)
        msg = "couldn't match choice:\n"

        @parsers.each do |p|
          r = p.parse_(input)
          if r.success?
            return r
          end

          msg += "    #{r.msg}\n"
        end

        failure(msg.chomp)
      end
    end

    #--------------------------------

    class Sequence < ArrayParser
      def initialize(*parsers)
        @parsers = parsers
      end

      def parse_(input)
        value = []

        @parsers.each do |p|
          r = p.parse_(input)
          unless r.success?
            return r
          end

          value << r.value
          input = r.remaining_input
        end

        success(value, input)
      end
    end

    #--------------------------------

    class Many < ArrayParser
      def initialize(parser)
        @parser = parser
      end

      def parse_(input)
        value = []

        loop do
          r  = @parser.parse_(input)

          unless r.success?
            return success(value, input)
          end

          value << r.value
          input = r.remaining_input
        end
      end
    end

    #--------------------------------

    # FIXME: it's a shame we can't construct this with:
    # sequence(parser, many(parser)) but the value comes out as [v1,
    # [v2, ...]], which suggests there's something wrong with how
    # values are being combined.
    class OneOrMore < ArrayParser
      def initialize(parser)
        @parser = parser
        @many = Many.new(parser)
      end

      def parse_(input)
        r1 = @parser.parse_(input)
        if r1.success?
          r2 = @many.parse_(r1.remaining_input)
          if r2.success?
            return success([r1.value] + r2.value, r2.remaining_input)
          else
            return success([r1.value], r1.remaining_input)
          end
        end

        return r1
      end
    end
  end

  # #--------------------------------
  # # A little set of combinators to build the parsers.
  # #--------------------------------

  def failure(msg)
    Detail::Fail.new(msg)
  end

  def literal(lit)
    Detail::Literal.new(lit)
  end

  def success(value)
    Detail::Success.new(value)
  end

  def choice(parser, *rest)
    Detail::Choice.new(parser, *rest)
  end

  def sequence(parser, *rest)
    Detail::Sequence.new(parser, *rest)
  end

  def many(parser)
    Detail::Many.new(parser)
  end

  def one_or_more(parser)
    Detail::OneOrMore.new(parser)
  end
end
