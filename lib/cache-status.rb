require 'lib/log'

#----------------------------------------------------------------

class CacheStatus
  attr_reader :md_used, :md_total, :read_hits, :read_misses, :write_hits, :write_misses
  attr_reader :demotions, :promotions, :residency, :nr_dirty

  # 12/1024 4538 3025 26714 62860 0 0 1024 216

  PATTERN ='\d+\s\d+\scache\s(\d+)/(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)'

  RX = Regexp.new(PATTERN)

  def initialize(cache_dev)
    status = cache_dev.status
    m = status.match(RX)
    if m.nil?
      raise "couldn't parse cache status '#{status}'"
    else
      @md_used = m[1].to_i
      @md_total = m[2].to_i
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
