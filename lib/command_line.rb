require 'lib/prelude'

require 'set'

#----------------------------------------------------------------

module CommandLine
  class CommandLineError < StandardError
  end

  class ParseError < CommandLineError
  end

  class ConfigureError < CommandLineError
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

  class Command
    attr_reader :switches

    def initialize
      @switches = []
      @mutually_exclusive_sets = [] # list of lists of syms
      @mandatory = []
    end

    def add_switches(syms)
      @switches += syms
    end

    def add_mutually_exclusive_set(syms)
      @mutually_exclusive_sets << syms.to_set
    end

    def add_mandatory_switch(sym)
      @mandatory << sym
    end

    def check_mutual_exclusion(syms)
      nr_sets = @mutually_exclusive_sets.size
      set_counts = Array.new(nr_sets, [])

      syms.each do |s|
        # is it in an exclusive set?
        0.upto(nr_sets - 1) do |n|
          if @mutually_exclusive_sets[n].member?(s)
            set_counts[n] << s
          end
        end
      end

      0.upto(nr_sets - 1) do |n|
        if set_counts[n].size > 1
          msg = "mutually exclusive options used:\n"
          set_counts[n].each {|sym| msg += "    #{sym}\n"}
          raise ParseError, msg
        end
      end
    end

    def check_mandatory(syms)
      missing = []

      @mandatory.each do |m|
        unless syms.member?(m)
          missing << m
        end
      end

      if missing.size > 0
        msg = "missing mandatory switches:\n"
        missing.each do |m|
          msg += "  #{m}\n"
        end

        raise ParseError, msg
      end
    end
  end

  class Parser
    GLOBAL_SYM = :global__

    def initialize(&block)
      @switches = {}
      @global_switches = []
      @value_types = {}
      @commands = Hash.new {|hash, key| Command.new}
      @current_command = @commands[GLOBAL_SYM]

      configure(&block) if block
    end

    def configure(&block)
      self.instance_eval(&block)
    end

    def value_type(sym, &parser)
      if @value_types.member?(sym)
        raise ConfigureError, "duplicate value type '#{sym}'"
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
      command(GLOBAL_SYM, &block)
    end

    def command(sym, &block)
      old = @current_command
      @current_command = @commands[sym] = Command.new

      if block
        release = lambda {@current_command = old}
        bracket_(release) do
          self.instance_eval(&block)
        end
      end
    end

    def switches(*syms)
      check_switches_are_defined(syms)
      @current_command.add_switches(syms)
    end

    def one_of(*syms)
      check_switches_are_defined(syms)
      @current_command.add_switches(syms)
      @current_command.add_mutually_exclusive_set(syms)
    end

    def mandatory(sym)
      syms = [sym]
      check_switches_are_defined(syms)
      @current_command.add_switches(syms)
      @current_command.add_mandatory_switch(sym)
    end

    def parse(handler, *args)
      command, opts, plain_args = parse_(args)
      handler.send(command, opts, plain_args)
    end

    private
    def parse_value(arg, s, args)
      if s.parser
        if args.size == 0
          raise ParseError, "no value specified for switch '#{arg}'"
        end

        value = args.shift
        begin
          s.parser.call(value)
        rescue => e
          raise ParseError, "couldn't parse value '#{arg}=#{value}'\n#{e}"
        end
      else
        true
      end
    end

    def parse_(args)
      in_command = false
      opts = {}
      plain_args = []
      valid_switches = @commands[GLOBAL_SYM].switches
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
            valid_switches = @commands[cmd].switches
            in_command = true
          else
            plain_args << arg
          end
        end
      end

      @commands[command].check_mutual_exclusion(opts.keys)
      @commands[command].check_mandatory(opts.keys)
      [command, opts, plain_args]
    end

    def check_switches_are_defined(syms)
      syms.each do |sym|
        raise ConfigureError, "unknown switch '#{sym}'" unless @switches.member?(sym)
      end
    end

    def find_switch(valid_switches, switch)
      catch :found do
        valid_switches.each do |sym|
          s = @switches[sym]
          if s.has_flag?(switch)
            throw :found, [sym, s]
          end
        end

        raise ParseError, "unexpected switch '#{switch}'"
      end
    end

    def get_value_parser(sym)
      if @value_types.member?(sym)
        @value_types[sym]
      else
        raise ConfigureError, "unknown value type '#{sym}'"
      end
    end
  end
end

#----------------------------------------------------------------
