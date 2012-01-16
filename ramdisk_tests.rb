require 'config'
require 'lib/dm'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class RamDiskTests < ThinpTestCase
  include Tags
  include Utils

  def setup
    super

    # I'm assuming you have set up 2G ramdisks (ramdisk_size=2097152 on boot)
    @data_dev = '/dev/ram1'
    @size = 2097152 * 2         # sectors
    @volume_size = 1900000
    #@data_block_size = 2 * 1024 * 8 # 8 M
  end

  tag :thinp_target

  def test_overwrite_a_linear_device
    linear_table = Table.new(Linear.new(@volume_size, @data_dev, 0))
    @dm.with_dev(linear_table) {|linear_dev| wipe_device(linear_dev)}
  end

  tag :thinp_target

  def test_dd_benchmark
    with_standard_pool(@size, :zero => true) do |pool|

      info "wipe an unprovisioned thin device"
      with_new_thin(pool, @volume_size, 0) {|thin| wipe_device(thin)}

      info "wipe a fully provisioned thin device"
      with_thin(pool, @volume_size, 0) {|thin| wipe_device(thin)}

      info "wipe a snapshot of a fully provisioned device"
      with_new_snap(pool, @volume_size, 1, 0) {|snap| wipe_device(snap)}

      info "wipe a snapshot with no sharing"
      with_thin(pool, @volume_size, 1) {|snap| wipe_device(snap)}
    end
  end
end

#----------------------------------------------------------------
