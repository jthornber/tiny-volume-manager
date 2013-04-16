module CommandLine
  class CommandLineError < RuntimeError
  end

  class Switch
    attr_reader :flags, :cardinality

    def initialize(flags, cardinality)
      @flags = flags
      @cardinality = cardinality
    end

    def has_flag?(flag)
      @flags.member?(flag)
    end
  end

  class CommandLineHandler
    def initialize
      @switches = {}
      @global_switches = []
    end

    def add_switch(sym, flags, cardinality = :single)
      @switches[sym] = Switch.new(flags, cardinality)
    end

    def add_argument_type(sym, parser)
    end

    def add_global_switch(sym)
      raise CommandLineError, "unknown switch '#{sym}'" unless @switches.member?(sym)
      @global_switches << sym
    end

    def add_sub_command(sym, *switches)
    end

    def parse(handler, *args)
      global_opts = {}

      while args.size > 0 do
        arg = args.shift

        if arg =~ /^-/
          @global_switches.each do |gsym|
            s = @switches[gsym]
            if s.has_flag?(arg)
              global_opts[s] = true
              break
            end
          end
        end
      end

      handler.global_command({})
    end

    private
    def switch(s)
      raise ArgumentError, "unknown switch '#{s}'" unless @switches.member?(s)
      @switches[s]
    end
  end
end
