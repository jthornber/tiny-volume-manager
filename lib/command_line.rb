require 'prelude'

#----------------------------------------------------------------

module CommandLine
  class CommandLineError < RuntimeError
  end

  class Switch
    attr_reader :flags, :parser

    def initialize(flags, parser = nil)
      @flags = flags
      @parser = parser
    end

    def has_flag?(flag)
      @flags.member?(flag)
    end
  end

  class CommandLineHandler
    def initialize
      @switches = {}
      @global_switches = []
      @value_types = {}
      @context = :global__
      @commands = Hash.new {|hash, key| []}
    end

    def configure(&block)
      self.instance_eval(&block)
    end

    def value_type(sym, &parser)
      if @value_types.member?(sym)
        raise CommandLineError, "duplicate value type '#{sym}'"
      end

      @value_types[sym] = parser
    end

    def simple_switch(sym, *flags)
      @switches[sym] = Switch.new(flags)
    end

    def value_switch(sym, value_sym, *flags)
      @switches[sym] = Switch.new(flags, get_value_parser(value_sym))
    end

    def global(&block)
      with_context(:global__) do
        self.instance_eval(&block)
      end
    end

    def switches(*syms)
      syms.each do |sym|
        raise CommandLineError, "unknown switch '#{sym}'" unless @switches.member?(sym)
      end

      @commands[@context] += syms
    end

    def command(sym, *switches, &block)
      with_context(sym) do
        self.instance_eval(&block)
      end
    end

    def parse(handler, *args)
      global_opts = {}
      plain_args = []

      while args.size > 0 do
        arg = args.shift

        if arg =~ /^-/
          sym, s = find_global_switch(arg)
          global_opts[sym] = s.parser ? s.parser.call(args.shift) : true
        else
          plain_args << arg
        end
      end

      handler.global_command(global_opts, plain_args)
    end

    private
    def find_global_switch(switch)
      catch :found do
        @commands[:global__].each do |gsym|
          s = @switches[gsym]
          if s.has_flag?(switch)
            throw :found, [gsym, s]
          end
        end

        raise ArgumentError, "unknown global switch '#{switch}'"
      end
    end

    def get_value_parser(sym)
      if @value_types.member?(sym)
        @value_types[sym]
      else
        raise CommandLineError, "unknown value type '#{sym}'"
      end
    end

    def with_context(ctxt, &block)
      old_context = @context
      @context = ctxt
      release = lambda {@context = old_context}
      bracket_(release, &block)
    end
  end
end

#----------------------------------------------------------------
