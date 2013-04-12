require 'spec_helper'
require 'lib/tvm/tvm_api'

include TVM

#----------------------------------------------------------------

describe TVM do
  before :each do
    @metadata = YAMLMetadata.new
    @vm = VolumeManager.new(@metadata)
    @vm.wipe
  end

  def create_snaps(name, n)
    1.upto(n) do
      @vm.snap_volume(name)
    end
  end

  # FIXME: re-write these using a mock to stand in for the metadata abstraction
  describe "transactions" do
    describe "passdown to metadata object" do
      def check_passdown(sym)
        md = mock()
        vm = VolumeManager.new(md)
        md.should_receive(sym)
        vm.send(sym)
      end

      it "should passdown begin" do
        check_passdown(:begin)
      end
      
      it "should passdown abort" do
        check_passdown(:abort)
      end

      it "should passdown commit" do
        check_passdown(:commit)
      end

      it "should passdown status" do
        check_passdown(:status)
      end
    end

    # FIXME: move these to metadata tests
    describe '#begin' do
      it "should succeed if there is no pending transaction" do
        @vm.begin
      end

      it "should fail if there is a pending transaction" do
        @vm.begin
        expect {@vm.begin}.to raise_error(TransactionError, "begin requested when already in transaction")
      end
    end

    describe '#commit' do
      it "should fail if no preceeding begin" do
        expect {@vm.commit}.to raise_error(TransactionError)
      end

      it "should fail if there are no pending changes" do
        @vm.begin
        expect {@vm.commit}.to raise_error(TransactionError)
      end

      it "should pass if there is a pending transaction" do
        @vm.begin
        @vm.create_volume(name: 'vol1')
        @vm.commit
      end

      it "should close the transaction" do
        @vm.begin
        @vm.create_volume(name: 'vol1')
        @vm.commit

        @metadata.in_transaction?.should be_false
      end

      it "should record pending changes" do
        @vm.begin
        @vm.create_volume(name: 'foo')
        @vm.create_volume(name: 'bar')
        @vm.commit
        
        @vm.volume_by_name('foo').name.should == 'foo'
        @vm.volume_by_name('bar').name.should == 'bar'
      end
    end

    describe '#abort' do
      it "should fail if no preceeding begin" do
        expect {@vm.abort}.to raise_error(TransactionError)
      end

      it "should pass if there are no pending changes" do
        @vm.begin
        @vm.abort
      end

      it "should pass if there are pending changes" do
        @vm.begin
        @vm.create_volume(name: 'foo')
        @vm.abort
      end

      it "should close the transaction" do
        @vm.begin
        @vm.abort

        @metadata.in_transaction?.should be_false
      end

      it "should discard pending changes" do
        @vm.begin
        @vm.create_volume(name: 'foo')
        @vm.create_volume(name: 'bar')
        @vm.abort

        expect {@vm.volume_by_name('foo')}.to raise_error(RuntimeError, "unknown volume 'foo'")
        expect {@vm.volume_by_name('bar')}.to raise_error(RuntimeError, "unknown volume 'bar'")
      end
    end

    describe "#status" do
      it "should fail if not in a transaction" do
        expect {@vm.status}.to raise_error(TransactionError)
      end

      it "should return an empty status object if there are no changes" do
        @vm.begin
        status = @vm.status
        status.created.should == []
        status.modified.should == []
        status.deleted.should == []
      end

      it "should include any created volumes" do
        @vm.begin
        v = @vm.create_volume(name: 'fred')
        status = @vm.status
        status.created.should include(v)
      end
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
