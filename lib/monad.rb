module Monad
  # A monad is anything that implements these two methods.  You don't
  # have to derive from Monad, it's just here for documentation
  # purposes.
  class Monad
    def pure(v)
    end

    # (a -> M b) -> M a -> M b
    def bind(ma, a_to_mb)
    end
  end

  #--------------------------------

  def join(mma)
    mma.bind {|x| x}
  end

  # def sequence(mas)
  #   0.upto(mas.size - 1) do |n|
  #     ma = mas[n]
  #     rest = mas[(n + 1)..(mas.size - 1)]
  #     ma.bind do |a|

  #     end
  #   end
  # end
end

#----------------------------------------------------------------

# Maybe monad
module Maybe
  class Just
    attr_accessor :value

    def initialize(v)
      @value = v
    end

    def ==(rhs)
      rhs.is_just? == true && rhs.value == @value
    end

    def bind(&a_to_mb)
      a_to_mb(@value)
    end

    def is_just?
      true
    end
  end

  class Nothing
    def ==(rhs)
      rhs.is_just? == false
    end

    def is_just?
      false
    end

    def bind(&a_to_mb)
      self
    end
  end

  def self.pure(v)
    Just.new(v)
  end
end

#--------------------------------

# list monad
class Array
  def self.pure(v)
    [v]
  end

  # Should we have an instance version too?
  def bind(&a_to_mb)
    self.map do |a|
      a_to_mb.call(a)
    end.flatten
  end
end

#----------------------------------------------------------------
