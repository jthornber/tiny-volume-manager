require 'array_parser'

include ArrayParser

#----------------------------------------------------------------

describe ArrayParser do

  def should_parse(input)
    @p.parse(input).success?.should be_true
  end

  def should_not_parse(input)
    @p.parse(input).success?.should be_false
  end

  #--------------------------------

  describe "#parse" do
    it "should raise an ArrayParserError if asked to parse something that isn't an array" do
      expect do
        failure("it's monday").parse(78)
      end.to raise_error(ArrayParserError)
    end

    it "should not raise if given a valid parser and array" do
      failure("it's monday").parse([1, 2, 3])
    end
  end

  describe "failure" do
    before :each do
      @msg = "the quick brown ..."
      @p = failure(@msg)
    end

    it "should always fail" do
      should_not_parse([])
    end

    it "should set the error message correctly" do
      @p.parse([]).msg.should == @msg
    end
  end

  describe "success" do
    before :each do
      @value = 678
      @p = success(@value)
    end

    it "should always succeed" do
      should_parse([])
    end

    it "should always return the given value" do
      @p.parse([]).value.should == @value
    end

    it "should consume no arguments" do
      args = [1, 2, 3, 4]
      @p.parse(args).remaining_input.should == args
    end
  end

  describe "literals" do
    before :each do
      @p = literal("earwig")
    end

    it "should fail if the next item doesn't match" do
      should_not_parse(["woodlouse"])
    end
  end

  describe "choice" do
    it "should fail if given no parsers" do
      expect do
        p = choice()
      end.to raise_error
    end

    describe "single choice" do
      before :each do
        @p = choice(literal('fred'))
      end

      it "should parse if given 1 choice and correct input" do
        should_parse(['fred'])
      end

      it "should fail given 1 choice and bad input" do
        should_not_parse(['bassett'])
      end

      it "should fail with a sensible message" do
        msg = "couldn't match choice:\n    couldn't match literal 'fred'"
        @p.parse(['bassett']).msg.should == msg
      end
    end

    describe "two choices" do
      before :each do
        @p = choice(literal('fred'),
                    literal('barney'))
      end

      it "should parse if given input from the first choice" do
        should_parse(['fred'])
      end

      it "should parse if given input from the second choice" do
        should_parse(['barney'])
      end

      it "should fail if given input that matches neither" do
        should_not_parse(['bassett', 'fred', 'barney'])
      end

      it "should fail with a sensible message" do
        msg = "couldn't match choice:\n    couldn't match literal 'fred'\n    couldn't match literal 'barney'"
        @p.parse([]).msg.should == msg
      end
    end
  end

  describe "sequence" do
    it "should fail if given no parsers" do
      expect do
        p = sequence()
      end.to raise_error
    end

    describe "sequence of 1 element" do
      before :each do
        @p = sequence(literal('fred'))
      end

      it "should parse if given correct input" do
        should_parse(['fred'])
      end

      it "should fail if given bad input"do
        should_not_parse(['barney'])
      end

      it "should return an one element array if parsed" do
        @p.parse(['fred']).value.size.should == 1
      end
    end

    describe "sequence of 2 elements" do
      before :each do
        @p = sequence(literal('fred'),
                      literal('bassett'))
      end

      it "should parse if given correct input" do
        should_parse(['fred', 'bassett'])
      end

      it "should fail if given bad input" do
        should_not_parse(['foo', 'bassett'])
        should_not_parse(['fred', 'barney'])
        should_not_parse(['bassett', 'green'])
      end

      it "should return an array of 2 elements if parsed" do
        @p.parse(['fred', 'bassett']).value.size.should == 2
      end

      it "should give a sensible error message" do
        msg = "couldn't match sequence:\n    couldn't match literal 'fred'\n    couldn't match literal 'bassett'"
        @p.parse(['foo', 'bar']).msg.should == msg
      end
    end
  end
end

#----------------------------------------------------------------

