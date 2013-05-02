require "monad"

include Monad

#----------------------------------------------------------------

describe Monad do
  describe "standard ops" do
    # FIXME: test without relying on Array?

    it "should support join" do
      join([[1, 2, 3], [4, 5], [6, 7, 8]]).should == [1, 2, 3, 4, 5, 6, 7, 8]
    end

    it "should support sequence" do
      sequence([[1, 2], [2, 3]]).should == [[1, 2], [1, 3], [2, 2], [2, 3]]
    end
  end

  describe "maybe monad" do
    it "should support pure" do
      Maybe.pure(17).is_just?.should be_true
    end

    it "should let you access a wrapped value" do
      Maybe.pure(17).value.should == 17
    end

    it "should pass values on with bind" do
      Maybe.pure(17).bind {|n| n * 2}.should == Just.new(34)
    end
  end

  describe "list monad" do
    it "should return a single element list for pure" do
      Array.pure('fred').should == ['fred']
    end

    it "should call the bind block once for each element" do
      [1, 2, 3].bind {|n| [n, n]}.should == [1, 1, 2, 2, 3, 3]
    end

    it "should allow a lambda to be passed into bind" do
      double = lambda {|n| [n, n]}
      [1, 2, 3].bind(&double)
    end
  end
end

#----------------------------------------------------------------
