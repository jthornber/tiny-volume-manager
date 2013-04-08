require 'lib/tvm/volume'
require 'lib/tvm/volume_id'

require 'set'

#----------------------------------------------------------------

module TVM
  class VolumeManager
    attr_reader :volumes

    def initialize
      @volumes = Set.new
    end

    #--------------------------------

    def wipe_metadata(path)
      remove_file_if_present(path)
    end

    def save_metadata(path)
      File.open(path, 'w+') do |f|
        f.write(YAML.dump(@volumes))
      end
    end

    def load_metadata(path)
      if File.exist?(path)
        @volumes = YAML.load_file(path)
      end
    end
    
    #--------------------------------

    def create_volume(opts = Hash.new)
      name = opts.fetch(:name, nil)
      if name
        raise RuntimeError, "duplicate volume name" unless unique_name(name)
      end

      new_volume = Volume.new(VolumeId.new, opts)

      @volumes << new_volume
      new_volume
    end

    def snap_volume(name, opts = Hash.new)
      parent = volume_by_name(name)
      new_volume = Volume.new(VolumeId.new, parent_id: parent.volume_id)
      
      @volumes << new_volume
      new_volume
    end

    # Any volume that doesn't have a parent
    def root_volumes
      volumes.select {|vol| vol.parent_id == nil}
    end

    # Any volume with parent_id if given volume
    def child_volumes(name)
      parent = volume_by_name(name)
      volumes.select {|vol| vol.parent_id == parent.volume_id}
    end

    def volume_by_name(name)
      vol = volume_by_name_(name)
      raise RuntimeError, "unknown volume #{name}" unless vol
      vol
    end

    def volumes
      @volumes.to_a
    end

    def each_volume(&block)
      @volumes.each(&block)
    end

    private
    def remove_file_if_present(path)
      if File.exist?(path)
        STDERR.puts "removing #{path}"
        File::unlink(path)
      end
    end

    def volume_by_name_(name)
      volumes.each do |v|
        return v if v.name == name
      end

      nil
    end

    def unique_name(name)
      volume_by_name_(name) == nil
    end
  end
end
