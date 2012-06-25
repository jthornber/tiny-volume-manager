module StringUtils
  class StringTable
    def initialize
      @strings = Hash.new do |h, k|
        h[k] = h.size
      end
    end

    def add(str)
      @strings[str]
    end

    def each(&block)
      @strings.keys.sort.each do |k|
        block.call(k, @strings[k])
      end
    end

    def [](key)
      raise "string not in table '#{key}'" unless @strings.member?(key)
      @strings[key]
    end
  end
end
