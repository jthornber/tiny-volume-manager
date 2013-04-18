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
    def initialize(&block)
      @switches = {}
      @global_switches = []
      @value_types = {}
      @context = :global__
      @commands = Hash.new {|hash, key| []}

      configure(&block) if block
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
      command, opts, plain_args = parse_(args)
      handler.send(command, opts, plain_args)
    end

    private
    def parse_value(arg, s, args)
      if s.parser
        if args.size == 0
          raise ArgumentError, "no value specified for switch '#{arg}'"
        end

        value = args.shift
        begin
          s.parser.call(value)
        rescue
          raise ArgumentError, "couldn't parse value '#{arg}=#{value}'"
        end
      else
        true
      end
    end

    def parse_(args)
      in_command = false
      opts = {}
      plain_args = []
      valid_switches = @commands[:global__]
      command = :global_command

      while args.size > 0 do
        arg = args.shift

        if arg =~ /^-/
          sym, s = find_switch(valid_switches, arg)
          opts[sym] = parse_value(arg, s, args)

        else
          cmd = arg.intern

          if !in_command && @commands.member?(cmd)
            command = cmd
            valid_switches = @commands[cmd]
            in_command = true
          else
            plain_args << arg
          end
        end
      end

      [command, opts, plain_args]
    end

    def find_switch(valid_switches, switch)
      catch :found do
        valid_switches.each do |sym|
          s = @switches[sym]
          if s.has_flag?(switch)
            throw :found, [sym, s]
          end
        end

        raise ArgumentError, "unexpected switch '#{switch}'"
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
