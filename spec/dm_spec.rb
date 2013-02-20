require 'spec_helper'
require 'device-mapper/dm'

#----------------------------------------------------------------

include DM

def new_dev(name)
  dm = mock('dm interface')
  dev = DMDev.new(name, dm)
  [dev, dm]
end

def hands_down(method)
    name = 'foo'
    dev, dm = new_dev(name)
    dm.should_receive(method).with(dev.path)
    dev.send(method)
end

def hands_down_with_result(method, result, *args)
    name = 'foo'
    dev, dm = new_dev(name)
    dm.should_receive(method).with(dev.path, *args).and_return(result)
    dev.send(method, *args).should == result
end

describe DM::DMDev do
  it "should have a read-only name" do
    name = 'foo'
    dev, dm = new_dev(name)
    dev.name.should == name
    expect {dev.name = 'bar'}.to raise_error(NoMethodError)
  end

  it "should know where it's node is in the /dev tree" do
    name = 'foo'
    dev, dm = new_dev(name)
    dev.path.should == "/dev/mapper/#{name}"
  end

  it "should have a suspend method" do
    hands_down(:suspend)
  end

  it "should have a resume method" do
    hands_down(:resume)
  end

  it "should have a pause method that combines suspend/resume" do
    name = 'foo'
    dev, dm = new_dev(name)
    dm.should_receive(:suspend).with(dev.path)
    dev.pause do
      dm.should_receive(:resume).with(dev.path)
    end
  end

  it "should have a remove method" do
    hands_down(:remove)
  end

  it "should have a message method" do
    args = [123, 'one', 'two', 'three']
    hands_down_with_result(:message, true, *args)
  end

  it "should have a status method" do
    hands_down_with_result(:status, "ksldfk sldj sldjs ")
  end

  it "should have a table method" do
    hands_down_with_result(:table, "lsdkfjs sdljs sld fs\nsld f sdlkfjs ")
  end

  it "should have an info method" do
    hands_down_with_result(:info, "iwekoweiurwo ")
  end

  it "should have a dm_name method" do
    fake_info = "the quick brown fox\nMajor, minor: 45, 17\njumps over the lazy"
    
    name = 'foo'
    dev, dm = new_dev(name)
    dm.should_receive(:info).
      with("/dev/mapper/#{name}").
      and_return(fake_info)
    dev.dm_name.should == 'dm-17'
  end

  it "should raise if malformed info in dm_name" do
    fake_info = "the quick brown fox\nMajor, minor: , 17\njumps over the lazy"
    
    name = 'foo'
    dev, dm = new_dev(name)
    dm.should_receive(:info).
      with("/dev/mapper/#{name}").
      and_return(fake_info)
    expect {dev.dm_name}.to raise_error(RuntimeError)
end    

  it "should have an event_nr method" do
    fake_status = "the quick brown fox\nEvent number: 18 \njumps over the lazy"
    
    name = 'foo'
    dev, dm = new_dev(name)
    dm.should_receive(:status).
      with("/dev/mapper/#{name}", '-v').
      and_return(fake_status)
    dev.event_nr.should == 18
  end

  it "should raise if malformed status in event_nr" do
    fake_status = "the quick brown fox\nEvent nimber: 18 \njumps over the lazy"
    
    name = 'foo'
    dev, dm = new_dev(name)
    dm.should_receive(:status).
      with("/dev/mapper/#{name}", '-v').
      and_return(fake_status)
    expect {dev.event_nr}.to raise_error(RuntimeError)
  end

  it "should have a to_s method" do
    dev, dm = new_dev('foo')
    dev.to_s.should == dev.path
  end

  it "should have event_tracker method" do
    fake_status = "the quick brown fox\nEvent number: 18 \njumps over the lazy"

    name = 'foo'
    dev, dm = new_dev(name)
    dm.should_receive(:status).
      with("/dev/mapper/#{name}", '-v').
      and_return(fake_status)
    tracker = dev.event_tracker
    tracker.event_nr.should == 18
    tracker.device.should === dev
  end

  it "should have a discard method" # FIXME: I don't think so
  it "should have a queue limits method" # FIXME: not sure
  it "should keep track of active and inactive tables" # FIXME: not sure about this
end
