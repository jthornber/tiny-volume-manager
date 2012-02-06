require 'lib/log'

#----------------------------------------------------------------
class PoolStatus
  attr_reader :transaction_id, :used_metadata_blocks, :total_metadata_blocks, :used_data_blocks, :total_data_blocks, :held_root

  def parse_held_root(txt)
    case txt
    when '-':
        nil

    else
      txt.to_i
    end
  end

  def initialize(pool)
    m = pool.status.match(/(\d+)\s(\d+)\/(\d+)\s(\d+)\/(\d+)\s(\S+)/)
    if m.nil?
      raise RuntimeError, "couldn't get pool status"
    end

    @transaction_id = m[1].to_i
    @used_metadata_blocks = m[2].to_i
    @total_metadata_blocks = m[3].to_i
    @used_data_blocks = m[4].to_i
    @total_data_blocks = m[5].to_i
    @held_root = parse_held_root(m[6])
  end
end

#----------------------------------------------------------------
