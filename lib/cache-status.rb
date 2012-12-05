require 'lib/log'

#----------------------------------------------------------------

class CacheStatus
  attr_reader :md_used, :md_total, :read_hits, :read_misses, :write_hits, :write_misses
  attr_reader :demotions, :promotions, :residency, :nr_dirty, :migration_threshold
  attr_reader :policy1, :policy2, :policy3, :policy4

  # 12/1024 4538 3025 26714 62860 0 0 1024 216 policy_arg{0,}

  PATTERN ='\d+\s\d+\scache\s(\d+)/(\d+)(.*)'

  def initialize(cache_dev)
    m = cache_dev.status.match(PATTERN)
    if m.nil?
      raise "couldn't parse cache status"
    else
      @md_used,
      @md_total,
      @read_hits,
      @read_misses,
      @write_hits,
      @write_misses,
      @demotions,
      @promotions,
      @residency,
      @nr_dirty,
      @migration_threshold,
      @policy1,
      @policy2,
      @policy3,
      @policy4 = m[1..2].to_a + m[3].scan(/\s+\d+/).map! {|s| s.to_i }
    end
  end
end

class CacheTable
  attr_reader :metadata_dev, :cache_dev, :origin_dev, :block_size, :nr_feature_args, :feature_args, :nr_policy_args, :policy_args

  # start len "cache" md cd od bs #features feature_arg{1,} #policy_args policy_arg{0,}
  # 0 283115520 cache 254:12 254:13 254:14 512 1 writeback basic 0

  PATTERN ='\d+\s\d+\scache\s([\w:]+)\s([\w:]+)\s([\w:]+)\s(\d+)\s(\d+)\s(.*)'

  def initialize(cache_dev)
    m = cache_dev.table.match(PATTERN)
    if m.nil?
      raise "couldn't parse cache table"
    else
      a = m[1..-2].to_a + m[-1].scan(/\s\S+/)
      a.map! { |s| s.lstrip.rstrip }

      @metadata_dev,
      @cache_dev,
      @origin_dev,
      @block_size,
      @nr_feature_args = a.shift(3) + [a.shift.to_i] + [a.shift.to_i]
      @feature_args,
      @nr_policy_args = [a.shift(@nr_feature_args)] + [a.shift.to_i]
      @policy_args = [a.shift(@nr_policy_args)]
    end
  end
end

#----------------------------------------------------------------
