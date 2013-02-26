require 'spec_helper'
require 'lib/device-mapper/dm_lexical_operators'

describe DM::LexicalOperators do
  describe "with_dev" do
    it "should create a new device" do
      dm = mock('dm interface')
      
    end

    it "should load the given table"
    it "should execute the block"
    it "should remove the device"
  end

  describe "with_devs" do
    it "should create several devices"
    it "should load the correct tables"
    it "should execute the block passing all the devices"
    it "should remove devices"
    it "should remove devices if there's an error during creation"
  end
end
