require 'array_parser'

include ArrayParser

#----------------------------------------------------------------

describe ArrayParser do
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
      @p.parse([]).success?.should be_false
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
      @p.parse([]).success?.should be_true
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
      @p.parse(["woodlouse"]).success?.should be_false
    end
  end

  describe "choice" do
    it "should fail if given no parsers" do
      expect do
        p = choice()
      end.to raise_error
    end

    describe "single parser" do
      before :each do
        @p = choice(literal('fred'))
      end

      it "should parse if given 1 choice and correct input" do
        @p.parse(['fred']).success?.should be_true
      end

      it "should fail given 1 choice and bad input" do
        @p.parse(['bassett']).success?.should be_false
      end

      it "should fail with a sensible message" do
        msg = "couldn't match choice:\n    couldn't match literal 'fred'"
        @p.parse(['bassett']).msg.should == msg
      end
    end
  end
end

#----------------------------------------------------------------

