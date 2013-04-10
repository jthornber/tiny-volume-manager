require 'lib/tvm/volume'
require 'lib/tvm/volume_id'

require 'set'
require 'yaml'

#----------------------------------------------------------------

module TVM
  class TransactionError < RuntimeError
  end

  class YAMLMetadata
    attr_reader :path
    attr_accessor :volumes, :in_transaction

    def initialize(path)
      @path = path
      @volumes = Set.new
      @in_transaction = false

      load_metadata
    end

    def begin
      if @in_transaction
        raise TransactionError, "begin requested when already in transaction"
      end

      load_metadata
      @in_transaction = true
    end

    def abort
      if !@in_transaction
        raise TransactionError, "abort requested but not in transaction"
      end

      @in_transaction = false
      load_metadata
    end

    def commit
      if !@in_transaction
        raise TransactionError, "commit requested but not in transaction"
      end

      @in_transaction = false
      save_metadata
    end

    def wipe_metadata
      remove_file_if_present(@path)
    end

    def save_metadata
      File.open(@path, 'w+') do |f|
        f.write(YAML.dump([@volumes, @in_transaction]))
      end
    end

    def load_metadata
      if File.exist?(@path)
        @volumes, @in_transaction = YAML.load_file(@path)
      end
    end

    private
    def remove_file_if_present(path)
      if File.exist?(path)
        File::unlink(path)
      end
    end
  end

  class VolumeManager
    attr_reader :metadata

    # FIXME: remove default arg
    def initialize(metadata = YAMLMetadata.new('./volumes.yaml'))
      @metadata = metadata
    end

    #--------------------------------

    def wipe
      @metadata.wipe_metadata
    end

    def begin
      @metadata.begin
    end

    def abort
      @metadata.abort
    end

    def commit
      @metadata.commit
    end

    #--------------------------------

    def create_volume(opts = Hash.new)
      name = opts.fetch(:name, nil)
      if name
        raise RuntimeError, "duplicate volume name" unless unique_name(name)
      end

      new_volume = Volume.new(VolumeId.new, opts)

      @metadata.volumes << new_volume
      new_volume
    end

    def snap_volume(name, opts = Hash.new)
      parent = volume_by_name(name)
      new_volume = Volume.new(VolumeId.new, parent_id: parent.volume_id)

      @metadata.volumes << new_volume
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
      @metadata.volumes.to_a
    end

    def each_volume(&block)
      @metadata.volumes.each(&block)
    end

    private
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
