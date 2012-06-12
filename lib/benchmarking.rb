require 'lib/log'

#----------------------------------------------------------------

module Benchmarking
  def report_time(desc, &block)
    elapsed = time_block(&block)
    info "Elapsed #{elapsed}: #{desc}"
  end
  
  #--------------------------------
  
  private
  def time_block
    start_time = Time.now
    yield
    return Time.now - start_time
  end
end

#----------------------------------------------------------------
