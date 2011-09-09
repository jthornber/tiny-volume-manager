require 'lib/log'

#----------------------------------------------------------------
class PoolStatus
  attr_reader :transaction_id, :free_metadata_sectors, :free_data_sectors, :held_root

  def initialize(pool)
    m = pool.status.match(/(\d+)\s(\d+)\s(\d+)\s(\S+)/)
    if m.nil?
      raise RuntimeError, "couldn't get pool status"
    end

    @transaction_id = m[1].to_i
    @free_metadata_sectors = m[2].to_i
    @free_data_sectors = m[3].to_i
    @held_root = m[4]
  end
end

#----------------------------------------------------------------
