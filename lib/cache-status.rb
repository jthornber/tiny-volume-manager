require 'lib/log'

#----------------------------------------------------------------

class CacheStatus
  attr_reader :read_hits, :read_misses, :write_hits, :write_misses
  attr_reader :demotions, :promotions, :residency, :nr_dirty

  def initialize(cache_dev)
    status = cache_dev.status
    m = status.match(/\d+\s\d+\scache\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)/)
    if m.nil?
      raise "couldn't parse cache status '#{status}'"
    else
      @read_hits = m[1].to_i
      @read_misses = m[2].to_i
      @write_hits = m[3].to_i
      @write_misses = m[4].to_i
      @demotions = m[5].to_i
      @promotions = m[6].to_i
      @residency = m[7].to_i
      @nr_dirty = m[8].to_i
    end
  end
end

#----------------------------------------------------------------
