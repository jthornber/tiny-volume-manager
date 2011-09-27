module Kernel
  def bracket(v, release)
    r = nil

    begin
      r = yield(v)
    ensure
      release.call(v)
    end
    r
  end

  def protect(v, release)
    r = nil

    begin
      r = yield(v)
    rescue Exception
      release.call(v)
      raise
    end

    r
  end
end
