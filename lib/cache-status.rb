require 'lib/log'

#----------------------------------------------------------------

class CacheStatus
  attr_reader :md_used, :md_total, :read_hits, :read_misses, :write_hits, :write_misses
  attr_reader :demotions, :promotions, :residency, :nr_dirty
  attr_reader :policy1, :policy2, :policy3, :policy4

  # 12/1024 4538 3025 26714 62860 0 0 1024 216 policy_arg{0,}

  PATTERN ='\d+\s\d+\scache\s(\d+)/(\d+)(.*)'

  def initialize(cache_dev)
    m = cache_dev.status.match(PATTERN)
    if m.nil?
      raise "couldn't parse cache status '#{status}'"
    else
      ( @md_used,
        @md_total,
        @read_hits,
        @read_misses,
        @write_hits,
        @write_misses,
        @demotions,
        @promotions,
        @residency,
        @nr_dirty,
        @policy1,
        @policy2,
        @policy3,
        @policy4 ) = (m[1..2] + m[3].scan(/\s\d+/)).map! {|s| s.to_i }
    end
  end
end

#----------------------------------------------------------------
