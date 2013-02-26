require 'spec_helper'
require 'lib/device-mapper/dm'

include DM

class CountedPredicate
  def initialize(n)
    @n = n
  end

  def call
    r = (@n == 0)
    @n -= 1
    r
  end
end

def counted(n)
  cp = CountedPredicate.new(n)
  lambda do
    cp.call
  end
end

describe DM::DMEventTracker do
  it "should not wait if the condition is immediately true" do
    predicate = lambda {true}

    dev = mock('dm dev')
    dev.should_not_receive(:wait)
    tracker = DMEventTracker.new(18, dev)
    tracker.wait(&predicate)
  end

  it "should wait if the condition is false" do
    predicate = counted(1)

    dev = mock('dm dev')
    dev.should_receive(:wait).with(18)
    dev.should_receive(:event_nr).and_return(19)
    tracker = DMEventTracker.new(18, dev)
    tracker.wait(&predicate)
  end

  it "should wait repeatedly until the condition is true" do
    predicate = counted(100)

    dev = mock('dm dev')
    tracker = DMEventTracker.new(18, dev)

    dev.should_receive(:wait).exactly(100).times
    dev.should_receive(:event_nr).exactly(100).times.and_return(19)
    tracker.wait(&predicate)
  end
end
