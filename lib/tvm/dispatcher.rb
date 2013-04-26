require 'lib/disk-units'
require 'lib/log'
require 'lib/tvm/tvm_api'
require 'lib/tvm/command_line'
require 'lib/tvm/dispatcher'

include DiskUnits
include Log

#----------------------------------------------------------------

module TVM
  class Dispatcher
    def initialize(vm)
      @vm = vm
    end

    def create(opts, args)
      raise RuntimeError, "incorrect number of arguments" if args.size != 1
      new_volume = @vm.create_volume(name: args[0])
      puts new_volume.volume_id
    end

    def snap(opts, args)
      @vm.snap_volume args[0]
    end

    def list(opts, args)
      show_children = true

      if args.size == 1
        vols = [@vm.volume_by_name(args[0])]
        show_children = false
      else
        vols = @vm.root_volumes
      end

      vols.each do |volume|
        puts_volume(volume)

        if show_children
          @vm.child_volumes(volume.name).each do |child|
            puts_volume(child, 2)
          end
        end
      end
    end

    def abort(opts, args)
      @vm.abort
    end

    def commit(opts, args)
      @vm.commit
    end

    def resize(opts, args)
      raise ArgumentError, "please specify the volume to be resized" unless args.size > 0
      raise ArgumentError, "too many arguments" unless args.size == 1
      # FIXME: check grow, grows etc.

      name = args[0]
      vol = @vm.volume_by_name(name)
      new_size = nil

      if opts.keys.member? :size
        new_size = opts[:size]

        if new_size == vol.size
          raise ArgumentError, "pointless resize op: new size is the same as old size"
        end

      elsif opts.keys.member? :grow_by
        new_size = vol.size + opts[:grow_by]

        if new_size == vol.size
          raise ArgumentError, "pointless resize op: new size is the same as old size"
        end

      elsif opts.keys.member? :shrink_by
        amount = opts[:shrink_by]

        if amount > vol.size
          raise ArgumentError, "cannot shrink '#{name}' by #{amount.format}"
        end

        new_size = vol.size - amount

      elsif opts.keys.member? :grow_to
        new_size = opts[:grow_to]

        if new_size <= vol.size
          raise ArgumentError, "--grow-to given a size that is <= to current"
        end

      elsif opts.keys.member? :shrink_to
        new_size = opts[:shrink_to]

        if new_size >= vol.size
          raise ArgumentError, "--shrink-to given a size that is >= to current"
        end

      else
        raise ArgumentError, "please specify one of --size, --grow-to, --grow-by, --shrink-to, --shrink-by"
      end

      @vm.resize(vol, new_size)
    end

    def status(opts, args)
      status = @vm.status

      puts "# created volumes:"
      puts "#"
      status.created.each do |vol|
        puts "#    #{vol.name_or_short_id}"
      end
      puts "#" if status.created.size > 0

      puts "# modified volumes:"
      puts "#"
      status.modified.each do |vol|
        puts "#    #{vol.name_or_short_id}"
      end
      puts "#" if status.modified.size > 0

      puts "# deleted volumes:"
      puts "#"
      status.deleted.each do |vol|
        puts "#    #{vol.name_or_short_id}"
      end
    end

    def global_command(opts, args)
      if args.size > 0
        die "unknown command '#{args[0]}'"
      else
        if opts[:help]
          help(STDOUT)
        else
          die "no command given"
        end
      end
    end

    private
    def die(msg)
      STDERR.puts msg
      exit(1)
    end

    def puts_volume(volume, indent = 0)
      time = volume.create_time.to_s.chomp
      puts "#{" " * indent}#{volume.volume_id} #{time} #{volume.name}"
    end

    # Pick out the option that's been given, from a set of mutually
    # exclusive options.
    def msg_list_options(opts)
      # FIXME: use a fold, and write an rspec test
      msg = ""

      opts.each do |o|
        msg += "\n    #{o}"
      end

      msg
    end

    def help(out)
      out.write <<EOF
tiny volume manager
  --help, -h:   Show this message
EOF
    end
  end
end

#----------------------------------------------------------------
