require 'spec_helper'
require 'lib/tvm/volume_id'
require 'lib/tvm/volume'

include TVM

#----------------------------------------------------------------

describe Volume do
  it "should be created with an id" do
    v1 = Volume.new(VolumeId.new)
    expect {Volume.new}.to raise_error(ArgumentError)
  end

  it "should have an optional 'name' field" do
    name = 'debian-image'

    v = Volume.new(VolumeId.new, :name => name)
    v.name.should == name
  end

  it "should have an optional 'parent_id' field" do
    parent_id = VolumeId.new
    v = Volume.new(VolumeId.new, parent_id: parent_id)
    v.parent_id.should == parent_id
  end

  describe "sizing" do
    before :each do
      @v = Volume.new(VolumeId.new, name: 'fred')
    end

    it "should be created with zero size" do
      @v.size.bytes.should == 0
    end

    it "should allow the size to be changed" do
      @v.size = DiskUnits::DiskSize.new(1, :gibibyte)
      @v.size.should == DiskUnits::DiskSize.new(1, :gibibyte)
    end
  end
end

#----------------------------------------------------------------
