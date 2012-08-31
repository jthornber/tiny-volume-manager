class QueueLimits
  def initialize
  end

  def queue_limit_file(dev_name, name)
    "/sys/block/#{dev_name}/queue/#{name}"
  end

  def get_queue_limit(dev_name, name)
    filename = queue_limit_file(dev_name, name)
    line = ''
    File.open(filename, 'r') do |file|
      line = file.gets
      line.chomp
      debug "#{filename} => #{line}"
    end

    line.to_i
  end

end
