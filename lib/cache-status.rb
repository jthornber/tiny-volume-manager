require 'lib/log'

#----------------------------------------------------------------

class CacheStatus
  attr_reader :nr_used_blocks_metadata, :nr_blocks_metadata
  attr_reader :read_hits, :read_misses, :write_hits, :write_misses
  attr_reader :demotions, :promotions, :residency, :nr_dirty

  def initialize(cache_dev)
    status = cache.status
    m = status.match(/(\d+)\/(\d+)\s(\d+)\s(\d+)\/(\d+)\s(\d+)\/(\d+)\s(\d+)\s(\d+)\s(\d+)/)
    if m.nil?
      raise "couldn't parse cache status"
    else
      @nr_used_blocks_metadata = m[1].to_i
      @nr_blocks_metadata = m[2].to_i
      @read_hits = m[3].to_i
      @read_misses = m[4].to_i
      @write_hits = m[5].to_i
      @write_misses = m[6].to_i
      @demotions = m[7].to_i
      @promotions = m[8].to_i
      @residency = m[9].to_i
      @nr_dirty = m[10].to_i
    end
  end
end

#----------------------------------------------------------------
