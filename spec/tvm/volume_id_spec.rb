require 'spec_helper'
require 'lib/tvm/volume_id'

require 'set'

#----------------------------------------------------------------

describe VolumeId do
  describe "creating a new id" do
    it "should have 16 characters" do
      id = VolumeId.new
      id.to_s.length.should == 16
    end

    it "should be composed of hex digits only" do
      id = VolumeId.new
      id.to_s.should =~ /^[0-9a-e]+$/
    end

    it "should be different every time" do
      seen = Set.new

      1000.times do
        str = VolumeId.new.to_s
        seen.member?(str).should be_false
        seen << str
      end
    end
  end
end

#----------------------------------------------------------------
