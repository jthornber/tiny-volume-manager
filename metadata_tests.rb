require 'lib/tiny_volume_manager/metadata'
require 'test/unit'
require 'pp'

#----------------------------------------------------------------

class MetadataRender
  include Metadata

  def initialize
    @indent = 0
  end

  def display_metadata
    Volume.find(:all).each do |v|
      emit v
      indent {display_segments(v.segments)}
    end

    display_free_space
  end

  def display_segments(ss)
    ss.each do |s|
      emit s
      emit s.target unless s.target.nil?
      indent {display_segments(s.children)} if s.children
    end
  end

  def display_free_space
    emit "free space:"
    indent do
      Segment.find(:all, :conditions => "parent_id IS NULL and target_id IS NULL").each do |s|
        emit s
      end
    end
  end

  private
  INDENT = 4

  def indent
    @indent += INDENT
    yield
    @indent -= INDENT
  end

  def emit(str)
    puts "#{' ' * @indent}#{str}"
  end
end

class VolumeGroup
  include Metadata

  def add_pv(name, uuid, length)
    pv = Volume.create(:name => name, :uuid => uuid)

    # This segment represents free space because it has no parent
    # segment or associated target.
    pv.segments.create(:offset => 0, :length => length)
    pv
  end
end

#----------------------------------------------------------------

class TVMMetadataTests < Test::Unit::TestCase
  include Metadata

  DB_FILE = './metadata.db'
  CONNECTION_PARAMS = {
    :adapter => 'sqlite3',
    :database => DB_FILE
  }

  def setup
    File.delete(DB_FILE)
    open_metadata
    super
  end

  def teardown
    close_metadata
  end

  def close_metadata
    @metadata.close
  end

  def open_metadata
    @metadata = MetadataStore.new(CONNECTION_PARAMS)
  end

  def reopen_metadata
    close_metadata
    open_metadata
  end

  def display_metadata
    r = MetadataRender.new
    r.display_metadata
  end

  def test_create_store
    extent_size = 8196

    vg = VolumeGroup.new
    pv0 = vg.add_pv('pv0', 'KBMvbK-ZKHF-giLJ-MEqp-dgb7-j0r7-Q8iC0U', 93458 * extent_size)
    pv1 = vg.add_pv('pv1', 'KeR3R0-dQd8-CCnb-1iS7-ndev-1sLW-tT9fTF', 476931 * extent_size)
    pv2 = vg.add_pv('pv2', 'goKzR9-znn6-v0d6-cOfj-8fe7-Lflf-7f0Rwt', 28618 * extent_size)

    # Logical volumes
    ubuntu_root = Volume.create(:name => 'ubuntu_root',
                                :uuid => 'NWavSx-2cPb-vk8n-387g-OWsZ-884y-tw0Lwy')

    # This is a logical segment
    stripe = StripedTarget.new(:nr_stripes => 1)
    lv_seg = Segment.create(:offset => 0,
                            :length => 9536 * extent_size)
    lv_seg.target = stripe
    ubuntu_root.segments << lv_seg

    # Underneath the logical segment are some physical segments
    pv_seg = lv_seg.children.create(:offset => 0,
                                    :length => 9536 * extent_size)
    pv2.segments << pv_seg

    display_metadata
  end
end

#----------------------------------------------------------------
