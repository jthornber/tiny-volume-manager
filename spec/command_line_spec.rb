require 'spec_helper'
require 'lib/command_line'

include CommandLine

#----------------------------------------------------------------

describe "Parser" do
  before :each do
    @clh = Parser.new
  end

  def help_switch
      @clh.simple_switch :help, '--help', '-h'
  end

  describe "creation" do
    it "should take a config block" do
      block_watcher = mock()
      block_watcher.should_receive(:executed)

      clh = Parser.new do
        value_type :string do |str|
          str
        end

        block_watcher.executed
      end
    end
  end

  describe "value types" do
    it "should allow you to register new value types" do
      @clh.configure do
        value_type :string do |str|
          str
        end

        value_type :int do |str|
          str.to_i
        end
      end
    end

    it "should fail it you try and define a duplicate value type" do
      @clh.value_type :string do |str|
        str
      end

      expect do
        @clh.value_type :string do |str|
          str
        end
      end.to raise_error(ConfigureError, /string/)
    end
  end

  describe "switches are defined separately from commands" do
    it "should let you define binary switch" do
      help_switch
    end

    it "should fail if you try and define a switch that takes an unknown value type" do
      expect {@clh.value_switch :resize_to, :volume_size, '--resize-to'}.to raise_error(ConfigureError, /volume_size/)
    end

    it "should let you define an option that takes a single value" do
      @clh.configure do
        value_type :volume_size do |str|
          str.to_i
        end

        value_switch :resize_to, :volume_size, '--resize-to'
      end
    end
  end

  describe "global switches" do
    it "should let you bind global switch" do
      help_switch
      @clh.configure do
        global do
          switches :help
        end
      end
    end

    it "should raise an error if the switch hasn't been previously defined" do
      expect do
        @clh.global do
          switches :become_sentient
        end
      end.to raise_error(ConfigureError)
    end
  end

  describe "sub commands" do
    it "should let you register a command" do
      @clh.configure do
        command(:create) {}
      end
    end

    it "should let you omit the block for a command" do
      @clh.configure do
        command :create
      end
    end

    it "should let you bind switches" do
      @clh.configure do
        simple_switch :grow_to, '--grow-to'
        simple_switch :grow_by, '--grow-by'
        simple_switch :shrink_to, '--shrink-to'
        simple_switch :shrink_by, '--shrink-by'

        command :resize do
          switches :grow_to, :grow_by, :shrink_to, :shrink_by
        end
      end
    end
  end

  describe "parsing" do
    describe "global command" do
      it "should handle no switches" do
        handler = mock()
        handler.should_receive(:global_command).with({}, [])
        @clh.parse(handler)
      end

      it "should raise a ParseError if an unrecognised switch is used" do
        handler = mock()
        expect {@clh.parse(handler, '--go-back-in-time')}.to raise_error(ParseError, /--go-back-in-time/)
      end

      it "should handle binary switches" do
        handler = mock()
        handler.should_receive(:global_command).with({:help => true}, [])

        @clh.configure do
          simple_switch :help, '--help', '-h'
          global do
            switches :help
          end
        end

        @clh.parse(handler, '-h')
      end

      it "should handle multiple binary switches" do
        handler = mock()
        handler.should_receive(:global_command).with({:help => true, :ro => true}, [])

        @clh.configure do
          simple_switch :help, '--help', '-h'
          simple_switch :ro, '--read-only', '-r'

          global do
            switches :help, :ro
          end
        end

        @clh.parse(handler, '-h', '--read-only')
      end

      it "should handle valued switches" do
        handler = mock()

        @clh.configure do
          value_type :int do |str|
            str.to_i
          end

          value_switch :count, :int, '--count', '-c'

          global do
            switches :count
          end
        end

        handler.should_receive(:global_command).
          with({:count => 17}, [])
        @clh.parse(handler, '--count', '17')

        handler.should_receive(:global_command).
          with({:count => 17}, ['one', 'two'])
        @clh.parse(handler, 'one', '-c', '17', 'two')
      end

      it "should raise an ArgumentError if no value is given for a valued switch" do
        handler = mock()

        @clh.configure do
          value_type :int do |str|
            str.to_i
          end

          value_switch :count, :int, '--count', '-c'

          global do
            switches :count
          end
        end

        expect do
          @clh.parse(handler, '--count')
        end.to raise_error(ParseError, /count/)
      end

      it "should filter non-switches out" do
        handler = mock()
        handler.should_receive(:global_command).
          with({:help => true, :ro => true}, ['my_file', 'my_other_file'])

        @clh.configure do
          simple_switch :help, '--help', '-h'
          simple_switch :ro, '--read-only', '-r'

          global do
            switches :help, :ro
          end
        end

        @clh.parse(handler, '-h', 'my_file', '--read-only', 'my_other_file')
      end
    end

    describe "simple commands" do
      it "should handle commands that take no switches" do
        @clh.configure do
          command :create do
          end
        end

        handler = mock()
        handler.should_receive(:create).with({}, ['fred'])
        @clh.parse(handler, 'create', 'fred')
      end
    end

    describe "commands" do
      before :each do
        @clh.configure do
          value_type :int do |str|
            str.to_i
          end

          value_switch :grow_to, :int, '--grow-to'
          value_switch :grow_by, :int, '--grow-by'
          value_switch :shrink_to, :int, '--shrink-to'
          value_switch :shrink_by, :int, '--shrink-by'

          command :resize do
            switches :grow_to, :grow_by, :shrink_to, :shrink_by
          end

          command :shrink do
            switches :grow_to, :grow_by, :shrink_to, :shrink_by
          end

          command :grow do
            switches :grow_to, :grow_by, :shrink_to, :shrink_by
          end
        end
      end

      it "should allow you to define a sub command" do
        handler = mock()
        handler.should_receive(:resize).with({:grow_to => 12345}, ['fred'])
        @clh.parse(handler, 'resize', '--grow-to', '12345', 'fred')
      end

      it "should prevent you calling two sub commands on the same line" do
        handler = mock()
        handler.should_receive(:resize).
          with({:grow_to => 1234, :shrink_to => 2345}, ['shrink', 'fred'])
        @clh.parse(handler, 'resize', '--grow-to', '1234', 'shrink', '--shrink-to', '2345', 'fred')
      end
    end

    describe "exclusive switches" do
      before :each do
        @clh.configure do
          value_type :int do |str|
            str.to_i
          end

          value_switch :grow_to, :int, '--grow-to'
          value_switch :grow_by, :int, '--grow-by'
          value_switch :shrink_to, :int, '--shrink-to'
          value_switch :shrink_by, :int, '--shrink-by'

          command :resize do
            one_of :grow_to, :grow_by, :shrink_to, :shrink_by
          end
        end
      end

      it "should parse one exclusive switch" do
        handler = mock()
        handler.should_receive(:resize).
          with({:grow_to => 1234}, ['fred'])
        @clh.parse(handler, 'resize', '--grow-to', '1234', 'fred')
      end

      it "should raise a ParseError if more than one switch from an exclusive set is defined" do
        handler = mock()
        expect do
          @clh.parse(handler, 'resize', '--grow-to', '1234', '--shrink-by', '2345', 'fred')
        end.to raise_error(ParseError, /mutually exclusive/)
        # FIXME: would be nice to see the actual flags in the exception
      end

      it "should let you define more than one exclusive set" do
        pending
      end
    end

    it "should handle --foo=<value>" do
      pending "todo"
    end
  end

  describe "mandatory switches" do
    before :each do
      @clh.configure do
        value_type :int do |str|
          str.to_i
        end

        value_switch :grow_to, :int, '--grow-to'
        value_switch :grow_by, :int, '--grow-by'
        value_switch :shrink_to, :int, '--shrink-to'
        value_switch :shrink_by, :int, '--shrink-by'

        command :resize do
          mandatory :grow_to
        end
      end
    end

    it "should parse ok if mandatory switch is given" do
      handler = mock()
      handler.should_receive(:resize).
        with({:grow_to => 3}, ['fred'])
      @clh.parse(handler, 'resize', '--grow-to', '3', 'fred')
    end

    it "should raise a ParseError if a mandatory switch is omitted" do
      handler = mock()
      expect do
        @clh.parse(handler, 'resize', 'fred')
      end.to raise_error(ParseError, /grow_to/)
    end
  end
end

#----------------------------------------------------------------
