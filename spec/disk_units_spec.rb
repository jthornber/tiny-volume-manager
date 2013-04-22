require 'spec_helper'
require 'lib/disk-units'

include DiskUnits

#----------------------------------------------------------------

describe DiskSize do
  it "should raise if an unknown unit is given" do
    expect {DiskSize.new(42, :fish)}.to raise_error(RuntimeError, /unknown disk unit ':fish'/)
  end

  it "should understand bytes" do
    size = DiskSize.new(1, :byte)
    size.in_bytes.should == 1
  end

  it "should understand kilobytes" do
    DiskSize.new(1, :kilobyte).in_bytes.should == 1000
  end

  it "should be able to give units in kilobytes" do
    DiskSize.new(17000, :byte).in_kilobytes.should == 17
  end

  describe "unit selection" do
    it "should choose a unit that's an exact factor" do
      DiskSize.new(17000, :byte).best_unit.should == :kilobyte
      DiskSize.new(17 * 1024, :byte).best_unit.should == :kibibyte
    end
  end

  describe "equality" do
    it "should compare bytes and ignore the defining unit" do
      DiskSize.new(127000, :byte).should == DiskSize.new(127, :kilobyte)
    end
  end

  describe "arithmetic" do
    it "should support (+)" do
      s = DiskSize.new(17, :byte)
      t = s + DiskSize.new(2, :gigabyte)
      t.in_bytes.should == (2 * 10**9) + 17
      s.in_bytes.should == 17
    end

    it "should support (+=)" do
      s = DiskSize.new(17, :byte)
      s += DiskSize.new(2, :gigabyte)
      s.in_bytes.should == (2 * 10**9) + 17
    end
  end

  describe "formatting" do
    it "should format in any requested unit" do
      tests = [[372, :byte, :byte, "372B"],
               [372, :byte, :sector, "0+sectors"],
               [372, :sector, :sector, "372sectors"],
               [17, :gigabyte, :megabyte, "17000MB"],
               [1, :gibibyte, :gigabyte, "1+GB"],
               [17, :gibibyte, :gigabyte, "18+GB"]
              ]

      tests.each do |s, in_u, out_u, str|
        DiskSize.new(s, in_u).format_size(out_u).should == str
      end
    end
  end

  describe "parsing" do
    it "should raise if given a nonsense" do
      expect {DiskSize.parse("lskd9832")}.to raise_error(RuntimeError)
    end

    it "should raise if given a nonsense prefix" do
      expect {DiskSize.parse("blip34GB")}.to raise_error(RuntimeError)
    end

    it "should raise if given a nonsense postfix" do
      expect {DiskSize.parse("34GBblip")}.to raise_error(RuntimeError)
    end

    it "should handle all suffixes" do
      tests = [["372B", 372],
               ["1kB", 1000],
               ["17kB", 17000],
               ["34KiB", 34 * 1024],
               ["1GB", 10**9]
              ]

      tests.each do |str, bytes|
        DiskSize.parse(str).in_bytes.should == bytes
      end
    end
  end
end

#----------------------------------------------------------------
