require 'lib/device-mapper/dm_event_tracker'
require 'lib/log'
require 'lib/prelude'
require 'lib/utils'

module DM
  # This hands off most of it's work to DMInterface
  class DMDev
    # FIXME: really not sure about active_table
    attr_reader :path, :interface, :active_table

    def initialize(path, interface)
      @path = path
      @interface = interface
    end

    def load(table)
      @interface.load(path, table)

      # FIXME: not active yet!
      @active_table = table
    end

    def suspend
      @interface.suspend(path)
    end

    def resume
      @interface.resume(path)
    end

    def pause(&block)
      suspend
      bracket_(method(:resume), &block)
    end

    def remove
      @interface.remove(path)
    end

    def message(sector, *args)
      @interface.message(path, sector, *args)
    end

    def status
      @interface.status(path)
    end

    def table
      @interface.table(path)
    end

    def info
      @interface.info(path)
    end

    def wait(event_nr)
      @interface.wait(path, event_nr)
    end

    def dm_name
      m = /Major, minor:\s*\d+, (\d+)/.match(info)
      raise "Couldn't find minor number for dm device in info" unless m

      "dm-#{m[1]}"
    end

    def event_nr
      output = @interface.status(path, '-v')
      m = output.match(/Event number:[ \t]*([0-9]+)/)
      if m.nil?
        raise "Couldn't find event number for dm device"
      end

      m[1].to_i
    end

    def event_tracker(&condition)
      DMEventTracker.new(event_nr, self)
    end

    #--------------------------------
    # FIXME: the rest of these methods should go elsewhere
    def post_remove_check
      @active_table.targets.each do |target|
        if target.public_methods.member?('post_remove_check')
          target.post_remove_check
        end
      end
    end

    def to_s
      path
    end

    # discards bytes delimited by b (begin, inclusive) and e (end,
    # non-inclusive).  b and e are given in 512 byte sectors.
    BLKDISCARD = 4727

    def discard(b, e)
      File.open(path, File::RDWR | File::NONBLOCK) do |ctrl|
        ctrl.ioctl(BLKDISCARD, [b * 512, e * 512].pack('QQ'))
      end
    end

    def queue_limits
      QueueLimits.new(dm_name)
    end
  end
end
