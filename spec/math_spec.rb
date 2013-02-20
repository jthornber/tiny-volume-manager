require 'spec_helper'
require 'math-utils'

include MathUtils

describe 'MathUtils::round_up' do
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

describe 'MathUtils::round_down' do
  it 'should round down divisions with a remainder' do
    round_down(4, 3).should == 3
    round_down(5, 3).should == 3

    round_down(101, 100).should == 100
    round_down(199, 100).should == 100
  end

  it 'should not round down divisions without a remainder' do
    round_down(3, 3).should == 3
    round_down(6, 3).should == 6
    round_down(100, 100).should == 100
    round_down(200, 200).should == 200
    round_down(200, 2).should == 200
  end
end

describe 'MathUtils::div_up' do
  it 'should round up divisions with a remainder' do
    div_up(4, 3).should == 2
    div_up(5, 3).should == 2

    div_up(101, 100).should == 2
    div_up(199, 100).should == 2
  end

  it 'should not round up divisions without a remainder' do
    div_up(3, 3).should == 1
    div_up(6, 3).should == 2

    div_up(100, 100).should == 1
    div_up(200, 100).should == 2
    div_up(200, 2).should == 100
  end
end
