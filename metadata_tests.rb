require 'lib/tiny_volume_manager/metadata'
require 'test/unit'
require 'pp'

#----------------------------------------------------------------

class TVMMetadataTests < Test::Unit::TestCase
  include Metadata

  def test_create_store
    MetadataStore.new(':memory:')

    extent_size = 8196

    # Add a physical volumes
    pv0 = Volume.create(:name => 'pv0',
                        :uuid => 'KBMvbK-ZKHF-giLJ-MEqp-dgb7-j0r7-Q8iC0U')

    pv1 = Volume.create(:name => 'pv1',
                        :uuid => 'KeR3R0-dQd8-CCnb-1iS7-ndev-1sLW-tT9fTF')

    pv2 = Volume.create(:name => 'pv2',
                        :uuid => 'goKzR9-znn6-v0d6-cOfj-8fe7-Lflf-7f0Rwt')

    # Logical volumes
    ubuntu_root = Volume.create(:name => 'ubuntu_root',
                                :uuid => 'NWavSx-2cPb-vk8n-387g-OWsZ-884y-tw0Lwy')

    # This is a logical segment
    lv_seg = Segment.create(:offset => 0,
                            :length => 9536 * extent_size)
    ubuntu_root.segments << lv_seg

    # Underneath the logical segment are some physical segments
    pv_seg = lv_seg.children.create(:offset => 0,
                                    :length => 9536 * extent_size)
    pp pv_seg
    pv2.segments << pv_seg

    pp pv_seg.root

#    s = Segment.new do |s|
#      s.offset = 0
#      s.length = 234234823
#    end

#    pv.segments << s
#    pv.save!

#    l = LinearTarget.new do |l|
#      l.offset = 0
#      l.segment = s
#    end

#    lv.linear_targets << l
#    lv.save!
  end
end

#----------------------------------------------------------------
