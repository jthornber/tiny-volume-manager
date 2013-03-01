require 'spec_helper'
require 'lib/device_mapper'

#----------------------------------------------------------------

describe DM::DMDev do
  include DM

  before :each do
    @path = '/dev/mapper/foo'
    @dm = mock('dm interface')
    @dev = DM::DMDev.new(@path, @dm)
  end

  def hands_down(method, *args)
    @dm.should_receive(method).with(@dev.path, *args)
    @dev.send(method, *args)
  end

  def hands_down_with_result(method, result, *args)
    @dm.should_receive(method).with(@dev.path, *args).and_return(result)
    @dev.send(method, *args).should == result
  end

  it "should have a read-only path" do
    expect {@dev.path = 'bar'}.to raise_error(NoMethodError)
  end

  it "should know where it's node is in the /dev tree" do
    @dev.path.should == @path
  end

  it "should hand down load" do
    hands_down(:load, mock())
  end

  it "should hand down suspend" do
    hands_down(:suspend)
  end

  it "should hand down resume" do
    hands_down(:resume)
  end

  it "should have a pause method that combines suspend/resume" do
    @dm.should_receive(:suspend).with(@dev.path)
    @dev.pause do
      @dm.should_receive(:resume).with(@dev.path)
    end
  end

  it "should hand down remove" do
    hands_down(:remove)
  end

  it "should hand down message" do
    args = [123, 'one', 'two', 'three']
    hands_down_with_result(:message, true, *args)
  end

  it "should hand down status" do
    hands_down_with_result(:status, "ksldfk sldj sldjs ")
  end

  it "should hand down table" do
    hands_down_with_result(:table, "lsdkfjs sdljs sld fs\nsld f sdlkfjs ")
  end

  it "should hand down info" do
    hands_down_with_result(:info, "iwekoweiurwo ")
  end

  it "should know it's dm-# name" do
    fake_info = "the quick brown fox\nMajor, minor: 45, 17\njumps over the lazy"

    @dm.should_receive(:info).with(@path).and_return(fake_info)
    @dev.dm_name.should == 'dm-17'
  end

  it "should raise if malformed info in dm_name" do
    fake_info = "the quick brown fox\nMajor, minor: , 17\njumps over the lazy"

    @dm.should_receive(:info).with(@path).and_return(fake_info)
    expect {@dev.dm_name}.to raise_error(RuntimeError)
  end

  it "should have an event_nr method" do
    fake_status = "the quick brown fox\nEvent number: 18 \njumps over the lazy"

    @dm.should_receive(:status).with(@path, '-v').and_return(fake_status)
    @dev.event_nr.should == 18
  end

  it "should raise if malformed status in event_nr" do
    fake_status = "the quick brown fox\nEvent nimber: 18 \njumps over the lazy"

    @dm.should_receive(:status).with(@path, '-v').and_return(fake_status)
    expect {@dev.event_nr}.to raise_error(RuntimeError)
  end

  it "should have a to_s method" do
    @dev.to_s.should == @dev.path
  end

  it "should have event_tracker method" do
    fake_status = "the quick brown fox\nEvent number: 18 \njumps over the lazy"

    @dm.should_receive(:status).with(@path, '-v').and_return(fake_status)
    tracker = @dev.event_tracker
    tracker.event_nr.should == 18
    tracker.device.should === @dev
  end

  it "should hand down wait" do
    hands_down(:wait, 18)
  end

  it "should have a discard method" # FIXME: I don't think so
  it "should have a queue limits method" # FIXME: not sure
  it "should keep track of active and inactive tables" # FIXME: not sure about this
end
