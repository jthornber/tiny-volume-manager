require 'spec_helper'
require 'lib/tvm'

include TinyVolumeManager

#----------------------------------------------------------------

describe TinyVolumeManager::VM do
  before :each do
    @vm = VM.new
  end

  def alloc_linear_vols(n, size)
    1.upto(n) do |v|
      @vm.add_volume(linear_vol("vol#{v}", size))
    end
  end

  def segment_total(segs)
    segs.inject(0) {|sum, s| sum + s.length}
  end

  #--------------------------------

  describe "a new volume manager" do
    it "should have no free space" do
      @vm.free_space.should == 0
    end

    it "should fail to allocate" do
      expect do
        @vm.add_volume(linear_vol(:vol1, 1))
      end.to raise_error(AllocationError)
    end
  end

  describe "a volume manager with space" do
    before :each do
      @vm.add_allocation_volume("space1", 0, 500)
      @vm.add_allocation_volume("space2", 0, 500)
    end

    it "should know how much free space it has" do
      @vm.free_space.should == 1000
    end

    it "should be able to allocate any space given to it" do
      alloc_linear_vols(5, 200)
      @vm.free_space.should == 0
    end

    it "should fail if asked to alloc too much" do
      expect do
        @vm.add_volume(linear_vol('vol1', 1001))
      end.to raise_error(AllocationError)
    end

    it "should allocate volumes with correct size" do
      @vm.add_volume(linear_vol('linear1', 123))
      segment_total(@vm.segments('linear1')).should == 123
    end
  end

  describe "after removing a volume" do
    before :each do
      @vm.add_allocation_volume('space', 0, 1000)
      @vm.add_volume(linear_vol('linear1', 123))
      @vm.remove_volume('linear1')
    end

    it "should not recognise the removed volume" do
      expect do
        @vm.segments('linear1')
      end.to raise_error(UnknownVolume)
    end

    it "should reallocate freed space" do
      @vm.add_volume(linear_vol('linear2', 1000))
    end

    it "should allow reuse of the name from a removed volume" do
      @vm.add_volume(linear_vol('linear1', 234))
      segment_total(@vm.segments('linear1')).should == 234
    end
  end

  it "should allow the extension of volumes" do
    @vm.add_allocation_volume('space', 0, 1000)

    len = 100
    @vm.add_volume(linear_vol('linear1', 100))

    9.times do
      len += 100
      @vm.resize('linear1', len)
    end

    expect do
      @vm.resize('linear1', len + 1)
    end.to raise_error(AllocationError)
  end

  pending 'we should be able to tag volumes'
  pending "we need to blur the distinction between PV's and LV's, eg a mirror is allocated from two+ legs"
  pending "activation"
  pending "persistence"
  pending "transactionality"
  pending "we mustn't realloc space within the same transaction"
end

#----------------------------------------------------------------
