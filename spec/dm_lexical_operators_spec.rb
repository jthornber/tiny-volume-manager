require 'spec_helper'
require 'lib/device-mapper/dm_lexical_operators'

describe DM::LexicalOperators do
  include DM::LexicalOperators

  before :each do
    @dm = mock('dm interface')
  end

  def dm_interface
    @dm
  end

  describe "with_dev" do
    it "should create a new device" do
      table = mock("dm table", :targets => [])
      table.stub :to_embed, :targets

      @dm.should_receive(:create)
      @dm.should_receive(:load) do |path, table2|
        table2.should equal(table)
      end
      @dm.should_receive(:resume)

      with_dev(table) do |dev|
        @dm.should_receive(:remove)
      end
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
