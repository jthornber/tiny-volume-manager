require 'lib/process'

module DM
  class DMInterface
    def create(path)
      ProcessControl.run("dmsetup create #{name} --notable")
    end

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
  end
end
