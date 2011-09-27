require 'lib/log'
require 'lib/dm'
require 'lib/prelude'

#----------------------------------------------------------------

module TinyVolumeManager

  Segment = Struct.new(:dev, :offset, :length)

  class Allocator
    def initialize
      @free_segments = Array.new
    end

    def allocate_segment(max_length)
      if @free_segments.size == 0
        raise RuntimeError, "out of free space"
      end

      s = @free_segments.shift
      if s.length > max_length
        @free_segments.unshift(Segment.new(s.dev, s.offset + max_length, s.length - max_length))
        s.length = max_length
      end
      s
    end

    def allocate_segments(target_size)
      release = lambda {|segs| release_segments(*segs)}

      protect(Array.new, release) do |result|
        while target_size > 0
          s = allocate_segment(target_size)
          target_size = target_size - s.length
          result << s
        end
        result
      end
    end

    def release_segments(*segs)
      @free_segments.push(*segs)
      @free_segments = @free_segments.sort_by {|s| [s.dev, s.offset]}

      merged = Array.new
      s = @free_segments.shift
      while @free_segments.size > 0
        n = @free_segments.shift
        if (n.dev == s.dev) && (n.offset == (s.offset + s.length))
          # adjacent, we can merge them
          s.length += n.length
        else
          # non-adjacent, push what we've got
          merged << s
          s = n
        end
      end
      merged << s
      @free_segments = merged
    end

    def free_space
      @free_segments.inject(0) {|sum, s| sum + s.length}
    end
  end

  VolumeDescription = Struct.new(:name, :length)

  # This class manages the allocation aspect of volume management.  It
  # generate dm tables, but does _not_ manage activation.  Use the
  # standard with_dev() method for that.
  class VM
    def initialize()
      @allocator = Allocator.new

      # Maps name -> [Description, segments]
      @volumes = Hash.new
    end

    # PV in LVM parlance
    def add_allocation_volume(dev, offset, length)
      @allocator.release_segments(Segment.new(dev, offset, length))
    end

    def member?(name)
      @volumes.member?(name)
    end

    def each(&block)
      @volumes.each_value(&block)
    end

    def free_space
      @allocator.free_space
    end

    def add_volume(desc)
      check_not_exist(desc.name)

      segments = @allocator.allocate_segments(desc.length)
      @volumes[desc.name] = [desc, segments]
    end

    def remove_volume(name)
      check_exists(name)
      @allocator.release_segments(*segments(name))
      @volumes.delete(name)
    end

    def desc(name)
      check_exists(name)
      desc, _ = @volumes[name]
      desc
    end

    def segments(name)
      check_exists(name)
      _, segments = @volumes[name]
      segments
    end

    def table(name)
      targets = Array.new
      segments(name).each do |seg|
        targets << Linear.new(seg.length, seg.dev, seg.offset)
      end
      Table.new(*targets)
    end

    private
    def check_not_exist(name)
      if @volumes.member?(name)
        raise RuntimeError, "Volume '#{name}' already exists"
      end
    end

    def check_exists(name)
      unless @volumes.member?(name)
        raise RuntimeError, "Volume '#{name}' doesn't exist"
      end
    end
  end
end

#----------------------------------------------------------------
