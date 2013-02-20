require 'lib/process'

module DM
  class DMInterface
    def suspend(path)
      ProcessControl.run("dmsetup suspend #{path}")
    end

    def resume(path)
      ProcessControl.run("dmsetup resume #{path}")
    end

    def remove(path)
      # FIXME: lift this retry?
      Utils.retry_if_fails(5.0) do
        if File.exists?(path)
          ProcessControl.run("dmsetup remove #{path}")
        end
      end
    end

    def message(name, sector, *args)
      ProcessControl.run("dmsetup message #{path} #{sector} #{args.join(' ')}")
    end

    def status(path, *args)
      ProcessControl.run("dmsetup status #{args} #{path}")
    end

    def table(path)
      ProcessControl.run("dmsetup table #{path}")
    end

    def info(path)
      ProcessControl.run("dmsetup info #{path}")
    end

    def wait(path, event_nr)
      # FIXME: it would be nice if this returned the new event nr
      ProcessControl.run("dmsetup wait #{path} #{event_nr}")
    end

    #--------------------------------
    # FIXME: move these to a mixin module

    def with_dev(table = nil, &block)
      bracket(create(table),
              lambda {|dev| dev.remove; dev.post_remove_check},
              &block)
    end

    def with_devs(*tables, &block)
      release = lambda do |devs|
        devs.each do |dev|
          begin
            dev.remove
            dev.post_remove_check
          rescue
          end
        end
      end

      bracket(Array.new, release) do |devs|
        tables.each do |table|
          devs << create(table)
        end

        block.call(*devs)
      end
    end

    def mk_dev(table = nil)
      create(table)
    end

    private
    def create(table = nil)
      name = create_name
      ProcessControl.run("dmsetup create #{name} --notable")
      protect_(lambda {ProcessControl.run("dmsetup remove #{name}")}) do
        dev = DMDev.new(name, self)
        unless table.nil?
          dev.load table
          dev.resume
        end
        dev
      end
    end

    def create_name()
      # fixme: check this device doesn't already exist
      "test-dev-#{rand(1000000)}"
    end
  end
end
