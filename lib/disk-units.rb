#----------------------------------------------------------------

module DiskUnits

  # FIXME: these three are deprecated
  def sectors(n)
    n
  end

  def meg(n)
    n * sectors(2048)
  end

  def gig(n)
    n * meg(1) * 1024
  end

  class DiskSize
    @units = {}

    def self.each(&block)
      @units.each(&block)
    end

    def self.lookup_unit(sym)
      raise RuntimeError, "unknown disk unit ':#{sym}'" unless @units.member?(sym)
      @units[sym]
    end

    def self.unit_by_suffix(str)
      @units.each do |unit, value|
        suffix, _ = value
        if suffix == str
          return unit
        end
      end

      raise RuntimeError, "unrecognised disk size suffix '#{str}'"
    end

    def self.define_unit(sym, suffix, size)
      @units[sym] = [suffix, size]

      define_method("in_#{sym}s".intern) do
        bytes / size
      end
    end

    #--------------------------------

    attr_accessor :bytes

    def initialize(n, unit = :byte)
      _, size = DiskSize.lookup_unit(unit)
      @bytes = n * size
    end

    def ==(rhs)
      @bytes == rhs.bytes
    end

    def +(rhs)
      self.class.new(@bytes + rhs.bytes, :byte)
    end

    def -(rhs)
      self.class.new(@bytes - rhs.bytes, :byte)
    end

    def >(rhs)
      @bytes > rhs.bytes
    end

    def >=(rhs)
      @bytes >= rhs.bytes
    end

    def <(rhs)
      @bytes < rhs.bytes
    end

    def <=(rhs)
      @bytes <= rhs.bytes
    end

    MATCHER = /^(\d+)([a-zA-Z]+)$/

    def self.parse(str)
      m = MATCHER.match(str)
      raise RuntimeError, "couldn't parse '#{str}'" unless m
      DiskSize.new(m[1].to_i, DiskSize.unit_by_suffix(m[2]))
    end

    def best_unit
      best = :byte
      best_value = @bytes

      DiskSize.each do |sym, value|
        _, size = value

        if @bytes % size == 0
          divided = @bytes / size

          if best_value > divided
            best = sym
            best_value = divided
          end
        end
      end

      best
    end

    def format_size(unit = best_unit)
      suffix, size = DiskSize.lookup_unit(unit)
      remainder = @bytes % size
      n = @bytes / size

      "#{n}#{remainder == 0 ? '' : '+'}#{suffix}"
    end

    define_unit(:byte, 'B', 1)
    define_unit(:sector, 'sectors', 512)

    define_unit(:kilobyte, 'kB', 10**3)
    define_unit(:megabyte, 'MB', 10**6)
    define_unit(:gigabyte, 'GB', 10**9)
    define_unit(:terabyte, 'TB', 10**12)
    define_unit(:petabyte, 'PB', 10**15)

    define_unit(:kibibyte, 'KiB', 2**10)
    define_unit(:mebibyte, 'MiB', 2**20)
    define_unit(:gibibyte, 'GiB', 2**30)
    define_unit(:tebibyte, 'TiB', 2**40)
    define_unit(:pebibyte, 'PiB', 2**50)
  end
end

#----------------------------------------------------------------

