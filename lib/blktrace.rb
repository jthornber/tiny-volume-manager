require 'lib/log'
require 'lib/process'

module BlkTrace
  include ProcessControl

  Event = Struct.new(:code, :start_sector, :len_sector)

  def follow_link(path)
    File.symlink?(path) ? File.readlink(path) : path
  end

  def to_event_type(cs)
    r = Array.new

    cs.each_char do |c|
      case c
      when 'D'
        r << :discard

      when 'R'
        r << :read

      when 'W'
        r << :write

      when 'S'
        r << :sync

      else
        raise "Unknown blktrace event type: '#{c}'"
      end
    end

    r
  end

  def blkparse(dev)
    # we need to work out what blktrace called this dev
    path = File.basename(follow_link(dev.to_s))

    events = Array.new
    pattern = /([DRW]) (\d+) (\d+)/
    `blkparse -f \"%d %S %N\n\" #{path}`.lines.each do |l|
      m = pattern.match(l)
      events.push(Event.new(to_event_type(m[1]), m[2].to_i, m[3].to_i / 512)) if m
    end

    events
  end

  def blktrace(*devs, &block)
    path = 'trace'

    consumer = LogConsumer.new

    flags = ''
    devs.each_index {|i| flags += "-d #{devs[i]} "}
    child = ProcessControl::Child.new(consumer, "blktrace #{flags}")
    sleep 1                     # FIXME: how can we avoid this race?
    r = block.call
    child.interrupt

    results = devs.map {|d| blkparse(d)}
    [results, r]
  end
end
