require 'spec_helper'
require 'lib/command_line'

include CommandLine

#----------------------------------------------------------------

describe "CommandLineHandler" do
  before :each do
    @clh = CommandLineHandler.new
  end

  def help_switch
      @clh.simple_switch :help, '--help', '-h'
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
      end.to raise_error(CommandLineError, /string/)
    end
  end

  describe "switches are defined separately from commands" do
    it "should let you define binary switch" do
      help_switch
    end

    it "should fail if you try and define a switch that takes an unknown value type" do
      expect {@clh.value_switch :resize_to, :volume_size, '--resize-to'}.to raise_error(CommandLineError, /volume_size/)
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
      end.to raise_error(CommandLineError)
    end
  end

  describe "sub commands" do
    it "should let you register a command" do
      @clh.configure do
        command(:create) {}
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

      it "should raise an ArgumentError if an unrecognised switch is used" do
        handler = mock()
        expect {@clh.parse(handler, '--go-back-in-time')}.to raise_error(ArgumentError, /--go-back-in-time/)
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

    describe "commands" do
      it "should allow you to define a sub command" do
        pending
      end
    end

    it "should handle switches with values" do
      pending
    end

    it "should handle --foo=<value>" do
      pending "todo"
    end
  end
end

#----------------------------------------------------------------
