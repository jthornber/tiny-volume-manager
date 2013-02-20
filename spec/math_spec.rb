require 'spec_helper'
require 'math-utils'

include MathUtils

module MathUtilsSpec
  describe 'round_up' do
    it "should round up divisions with a remainder" do
      round_up(4, 3).should == 6
      round_up(5, 3).should == 6

      round_up(101, 100).should == 200
      round_up(199, 100).should == 200
    end

    it "should not round up divisions without a remainder" do
      round_up(3, 3).should == 3
      round_up(6, 3).should == 6

      round_up(100, 100).should == 100
      round_up(200, 100).should == 200
      round_up(200, 2).should == 200
    end
  end
end
