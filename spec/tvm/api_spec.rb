require 'spec_helper'
require 'lib/tvm/tvm_api'

include TVM

#----------------------------------------------------------------

describe TVM do
  before :each do
    @vm = VolumeManager.new
  end

  def create_snaps(name, n)
    1.upto(n) do
      @vm.snap_volume(name)
    end
  end

  describe '#create_volume' do
    # FIXME: these tests should be applied to newly created snaps too

    it "should enforce a unique name" do
      name = 'fred'
      @vm.create_volume(name: name)
      expect {@vm.create_volume(name: name)}.to raise_error(RuntimeError)
    end
    
    it "should set the creation time" do
      vol = @vm.create_volume

      # FIXME: there must be a standard matcher for comparing times
      vol.create_time.to_f.should be_within(2).of(Time.now.to_f)
    end
  end

  describe "#snap_volume" do
    it "should fail if asked to snap an unknown volume" do
      @vm.create_volume(name: 'fred')

      expect {@vm.snap_volume('bassett')}.to raise_error(RuntimeError)
    end

    it "should succeed if asked to snap a known volume" do
      @vm.create_volume(name: 'fred')
      v = @vm.snap_volume('fred')
    end

    it "should create volumes with a parent_id attrib" do
      name = 'fred'
      parent = @vm.create_volume(name: name)
      v = @vm.snap_volume(name)
      v.parent_id.should == parent.volume_id
    end
  end

  describe '#volume_by_name' do
    it "should raise an error if there are no volumes" do
      expect {@vm.volume_by_name("fred")}.to raise_error(RuntimeError, /fred/)
    end

    it "should find a volume" do
      name = 'fred'
      @vm.create_volume(name: name)
      v = @vm.volume_by_name(name)

      v.name.should == name
    end

    it "should not find a volume" do
      name = 'fred'
      bad_name = 'bong'

      @vm.create_volume(name: name)
      expect {@vm.volume_by_name(bad_name)}.to raise_error(RuntimeError, /#{bad_name}/)
    end

  end

  describe "queries" do
    before :each do
      @name1 = 'fred'
      @name2 = 'barney'

      @root1 = @vm.create_volume(name: @name1)
      @root2 = @vm.create_volume(name: @name2)

      create_snaps(@name1, 7)
      create_snaps(@name2, 19)
    end

    describe "#root_volumes" do
      it "should return all volumes that do not have a parent defined" do
        roots = @vm.root_volumes
        roots.length.should == 2

        roots.map {|vol| vol.name}.sort.should == [@name2, @name1]
      end
    end

    describe "#child_volumes" do
      it "should return all volumes that have the given volume as a parent" do
        children = @vm.child_volumes(@name1)
        children.length.should == 7
        children.all? {|vol| vol.parent_id.should == @root1.volume_id}

        children = @vm.child_volumes(@name2)
        children.length.should == 19
        children.all? {|vol| vol.parent_id.should == @root2.volume_id}
      end
    end
  end

  describe "#volumes" do
    it "should return an empty array if there are no volumes" do
      @vm.volumes.size.should == 0
    end
  end
end

#----------------------------------------------------------------
