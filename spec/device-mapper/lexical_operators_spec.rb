require 'spec_helper'
require 'lib/device-mapper/lexical_operators'

describe DM::LexicalOperators do
  include DM::LexicalOperators

  before :each do
    @dm = mock('dm interface')
    @create_count = 0
  end

  def path(n)
    "dev-#{n}"
  end

  # We override the create_path method from LexicalOperators to force
  # known paths that we can check for in the arguments to dm_interface
  # hand downs.
  def create_path
    r = path(@create_count)
    @create_count += 1
    r
  end

  def dm_interface
    @dm
  end

  def mock_table(name = 'default')
    mock("dm table", :targets => [], :to_embed => "<I'm a table: #{name}>")
  end

  describe "#with_dev" do
    it "should create, load, resume, exec block, remove" do
      table = mock_table

      @dm.should_receive(:create).with(path(0)).ordered
      @dm.should_receive(:load).with(path(0), table).ordered
      @dm.should_receive(:resume).with(path(0)).ordered
      @dm.should_receive(:block_executed).ordered
      @dm.should_receive(:remove).with(path(0)).ordered

      with_dev(table) {|dev| @dm.block_executed}
    end
  end

  describe "#with_devs" do
    it "should create several devices" do
      nr = 100

      tables = Array.new

      0.upto(nr - 1) do |n|
        table = mock_table(n)
        tables << table

        @dm.should_receive(:create).with(path(n)).ordered
        @dm.should_receive(:load).with(path(n), table).ordered
        @dm.should_receive(:resume).with(path(n)).ordered
      end

      @dm.should_receive(:block_executed).ordered

      (nr - 1).downto(0) do |n|
        @dm.should_receive(:remove).with(path(n)).ordered
      end
      
      with_devs(*tables) do |*devs|
        @dm.block_executed

      end
    end

    it "should remove devices if there's an error during creation" do
      nr = 100
      nr_good = 43

      tables = Array.new

      0.upto(nr - 1) do |n|
        tables << mock_table(n)
      end

      0.upto(nr_good - 1) do |n|
        @dm.should_receive(:create).with(path(n)).ordered
        @dm.should_receive(:load).with(path(n), tables[n]).ordered
        @dm.should_receive(:resume).with(path(n)).ordered
      end

      @dm.should_receive(:create).with(path(nr_good)).ordered
      @dm.should_receive(:load).with(path(nr_good), tables[nr_good]).ordered.and_raise('load failed')
      @dm.should_receive(:remove).with(path(nr_good)).ordered
      
      #@dm.should_not_receive(:block_executed).ordered

      (nr_good - 1).downto(0) do |n|
        @dm.should_receive(:remove).ordered
      end

      expect do
        with_devs(*tables) do |*devs|
          @dm.block_executed
        end
      end.to raise_error
    end
  end
end
