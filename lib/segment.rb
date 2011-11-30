require 'lib/log'
require 'lib/prelude'

#----------------------------------------------------------------

module TinyVolumeManager
  class Segment < Struct.new(:begin, :end)
    def initialize(b, e)
      super(b, e)
    end

    def length
      self.end - self.begin
    end
  end

  class SegmentList
    attr_reader :segs

    def initialize
      @segs = Array.new
    end

    # divides an array of segments into 3 categories:
    # [segments below, segments overlapping, segments above]
    def partition(segs, seg)
      below = Array.new
      overlapping = Array.new
      above = Array.new

      segs.each do |s|
        if s.end < seg.begin
          below << s

        elsif seg.end <= s.begin
          above << s

        else
          overlapping << s
        end
      end

      [below, overlapping, above]
    end

    # we insert in the right place, being careful not to overlap or
    # break the ordering constraints.
    def add(seg)
      return if seg.end - seg.begin == 0

      below, overlapping, above = partition(@segs, seg)

      new_segs = Array.new
      new_segs.concat(below)
      if overlapping.size > 0
        new_segs << Segment.new(min(overlapping[0].begin, seg.begin),
                                max(overlapping[-1].end, seg.end))
      else
        new_segs << seg
      end
      new_segs.concat(above)

      @segs = new_segs
    end

    def rm(seg)
      return if seg.end - seg.begin == 0

      below, overlapping, above = partition(@segs, seg)

      new_segs = Array.new
      new_segs.concat(below)

      if overlapping.size > 0
        overlap_segment = Segment.new(overlapping[0].begin,
                                      overlapping[-1].end)

        if overlap_segment.begin < seg.begin
          new_segs << Segment.new(overlap_segment.begin, seg.begin)
        end

        if overlap_segment.end > seg.end
          new_segs << Segment.new(seg.end, overlap_segment.end)
        end
      end

      new_segs.concat(above)
      @segs = new_segs
    end

    def count
      @segs.length
    end

    def total
      @segs.inject(0) {|acc, s| acc += s.length}
    end

    def negate
      # FIXME: finish
    end

    # Rounds all segments to 'size' boundaries.  Beginnings get
    # rounded up, ends get rounded down.
    def quantise(size)
    end

    def each(&block)
      @segs.each(&block)
    end

    private
    def min(a, b)
      [a, b].sort[0]
    end

    def max(a, b)
      [a, b].sort[1]
    end
  end
end

#----------------------------------------------------------------
