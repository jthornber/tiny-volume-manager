
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
          r = p.parse(input)
          if r.success?
            return r
          end

          msg += "    #{r.msg}"
        end

        failure(msg)
      end
    end
  end

  #   #--------------------------------

  #   class Sequence
  #     def initialize(*parsers)
  #       @parsers = parsers
  #     end

  #     def parse(args)
  #       remaining_input = args
  #       value = []

  #       @parsers.each do |p|
  #         r = p.parse(remaining_input)
  #         unless r.parsed
  #           return fail_parse
  #         end

  #         value << r.value
  #         remaining_input = r.remaining_input
  #       end

  #       [true, value, remaining_input]
  #     end
  #   end

  #   #--------------------------------

  #   class ManyOf
  #     def initialize(parser)
  #       @parser = parser
  #     end

  #     def parse(args)
  #       results = []
  #       remaining = args

  #       loop do
  #         r  = @parser.parse(remaining)
  #         if r.parsed
  #           remaining = r.remaining_input
  #         else
  #           break
  #         end
  #       end

  #       [true, map(results) {|r| r.value}, remaining]
  #     end
  #   end
  # end

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


  # def set_value(parser, value)  # FIXME: better name?
  #   # FIXME: finish
  # end

  # def zero_or_more(parser)
  #   # FIXME: finish
  # end

  # def one_or_more(parser)
  #   sequence(parser, zero_or_more(parser))
  # end

  # def sequence(*parsers)
  #   # FIXME: finish
  # end


  # #--------------------------------

end
