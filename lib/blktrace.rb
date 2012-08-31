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

  def filter_events(event_type, events)
    # FIXME: support multiple event_types?
    r = Array.new
    events.each_index do |i|
      r.push(events[i]) if events[i].code.member?(event_type)
    end
    r
  end

  def assert_discard(traces, start_sector, length)
    assert(traces[0].member?(Event.new([:discard], start_sector, length)))
  end

  def assert_discards(traces, start_sector, length)
    events = filter_events(:discard, traces)
    assert(!events.empty?)

    start = events[0].start_sector
    len = 0
    events.each { |event| len += event.len_sector }

    assert(start_sector == start)
    assert(length == len)
  end

  def blkparse(dev)
    # we need to work out what blktrace called this dev
    path = File.basename(follow_link(dev.to_s))

    events = Array.new
    # we only match complete ios
    pattern = /C ([DRW]) (\d+) (\d+)/
    `blkparse -f \"%a %d %S %N\n\" #{path}`.lines.each do |l|
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
    begin
      sleep 0.1                     # FIXME: how can we avoid this race?
      r = block.call
    ensure
      child.interrupt
    end

    # results is an Array of Event arrays (one per device)
    results = devs.map {|d| blkparse(d)}
    [results, r]
  end
end
