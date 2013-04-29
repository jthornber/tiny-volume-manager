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

  describe "literals" do
    before :each do
      @p = literal("earwig")
    end

    it "should fail if the next item doesn't match" do
      @p.parse(["woodlouse"]).success?.should be_false
    end
  end
end

#----------------------------------------------------------------

