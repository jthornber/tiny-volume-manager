require 'lib/log'
require 'lib/dm'
require 'lib/prelude'

#----------------------------------------------------------------

module TinyVolumeManager

  # FIXME: define in terms of Segment
  DevSegment = Struct.new(:dev, :offset, :length)

  class Allocator
    def initialize
      @free_segments = Array.new
    end

    def allocate_segment(max_length)
      if @free_segments.size == 0
        raise "out of free space"
      end

      s = @free_segments.shift
      if s.length > max_length
        @free_segments.unshift(DevSegment.new(s.dev, s.offset + max_length, s.length - max_length))
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

  #----------------------------------------------------------------

  module Details
    class Volume
      attr_reader :name, :length, :segments, :targets, :allocated

      def initialize(n, l)
        @name = n
        @length = l
        @segments = nil
        @targets = nil
        @allocated = false
      end

      def resize(allocator, new_length)
        raise "resize not implemented"
      end

      def allocate(allocator)
        raise "allocate not implemented"
      end
    end

    class LinearVolume < Volume
      def initialize(n, l)
        super(n, l)
      end

      def resize(allocator, new_length)
        if !@allocated
          @length = new_length
          return
        end

        if new_length < @length
          raise "reduce not implemented"
        end

        new_segs = allocator.allocate_segments(new_length - @length)
        @segments.concat(new_segs)
        @targets.concat(LinearVolume.segs_to_targets(new_segs))
        @length = new_length
      end

      def allocate(allocator)
        @segments = allocator.allocate_segments(@length)
        @targets = LinearVolume.segs_to_targets(@segments)
        @allocated = true
      end

      private
      def self.segs_to_targets(segs)
        segs.map {|s| Linear.new(s.length, s.dev, s.offset)}
      end
    end
  end

  # Use these functions rather than explicitly instancing Volumes
  def linear_vol(n, l)
    Details::LinearVolume.new(n, l)
  end

  #----------------------------------------------------------------

  # This class manages the allocation aspect of volume management.  It
  # generate dm tables, but does _not_ manage activation.  Use the
  # standard with_dev() method for that.
  class VM
    attr_reader :volumes

    def initialize()
      @allocator = Allocator.new

      # Maps name -> [Description, segments]
      @volumes = Hash.new
    end

    # PV in LVM parlance
    def add_allocation_volume(dev, offset, length)
      @allocator.release_segments(DevSegment.new(dev, offset, length))
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

    def add_volume(vol)
      check_not_exist(vol.name)
      vol.allocate(@allocator)
      @volumes[vol.name] = vol
    end

    def remove_volume(name)
      check_exists(name)
      vol = @volumes[name]
      @allocator.release_segments(*vol.segments)
      @volumes.delete(name)
    end

    def resize(name, new_size)
      check_exists(name)
      @volumes[name].resize(@allocator, new_size)
    end

    def segments(name)
      check_exists(name)
      @volumes[name].segments
    end

    def targets(name)
      check_exists(name)
      @volumes[name].targets
    end

    def table(name)
      Table.new(*targets(name))
    end

    private
    def check_not_exist(name)
      if @volumes.member?(name)
        raise "Volume '#{name}' already exists"
      end
    end

    def check_exists(name)
      unless @volumes.member?(name)
        raise "Volume '#{name}' doesn't exist"
      end
    end
  end
end

#----------------------------------------------------------------
