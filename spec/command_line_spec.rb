require 'spec_helper'
require 'lib/command_line'

include CommandLine

#----------------------------------------------------------------

describe "CommandLineHandler" do
  before :each do
    @clh = CommandLineHandler.new
  end

  def help_switch
      @clh.add_switch(:help, ['--help', '-h'])
  end

  describe "argument types" do
    it "should allow you to register new argument types" do
      @clh.add_argument_type(:string, lambda {|str| str})
      @clh.add_argument_type(:int, lambda {|str| str.to_i})
    end
  end

  describe "options are defined separately from commands" do
    it "should let you define binary switch" do
      help_switch
    end

    it "should let you define an option that takes a single value" do
      @clh.add_switch(:resize_to, ['--resize-to'], :volume_size)
    end

    it "should let you define an option that takes a single value" do
      @clh.add_switch(:resize_to, ['--resize-to'], :volume_size)
    end
  end

  describe "global switches" do
    it "should let you bind global switch" do
      help_switch
      @clh.add_global_switch(:help)
    end

    it "should raise an error if the switch hasn't been previously defined" do
      expect {@clh.add_global_switch(:become_sentient)}.to raise_error(CommandLineError)
    end
  end

  describe "sub commands" do
    it "should let you register a sub command" do
      @clh.add_sub_command(:create)
    end

    it "should let you bind switches" do
      @clh.add_sub_command(:resize, :grow_to, :grow_by, :shrink_to, :shrink_by)
    end
  end

  describe "parsing" do
    describe "global command" do
      it "should handle no switches" do
        handler = mock()
        handler.should_receive(:global_command).with({})
        @clh.parse(handler)
      end

      it "should raise an ArgumentError if an unrecognised switch is used" do
        expect {@clh.parse(handler, '--go-back-in-time')}.to raise_error(ArgumentError, /--go-back-in-time/)
      end

      it "should handle binary switches" do
        handler = mock()
        handler.should_receive(:global_command).with(:help => true)

        @clh.add_switch(:help, ['--help', '-h'])
        @clh.add_global_switch(:help)
        @clh.parse(handler, '-h')
      end
    end

    it "should handle --foo=<value>" do
      pending "todo"
    end
  end
end

#----------------------------------------------------------------
