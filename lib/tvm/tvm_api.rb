require 'lib/log'
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
    attr_accessor :volumes, :pending_changes

    def initialize(path = './volumes.yaml')
      @path = path
      @pending_path = path + ".pending"

      load_or_init
    end

    def in_transaction?
      File.exist? @pending_path
    end

    def begin
      if in_transaction?
        raise TransactionError, "begin requested when already in transaction"
      end

      load @path
      save @pending_path
    end

    def abort
      if !in_transaction?
        raise TransactionError, "abort requested but not in transaction"
      end

      load(@path)
      remove_file_if_present(@pending_path)
    end

    def commit
      info "in commit"
      if !in_transaction?
        raise TransactionError, "commit requested but not in transaction"
      end

      if !@pending_changes
        raise TransactionError, "commit requested but no pending changes"
      end

      @pending_changes = false

      save(@path)
      remove_file_if_present(@pending_path)
    end

    def wipe
      remove_file_if_present(@pending_path)
      init
      save(@path)
    end

    def persist
      save(@pending_path)
    end

    private
    # FIXME: move to a utility module
    def remove_file_if_present(path)
      if File.exist?(path)
        info "unlinking #{path}"
        File::unlink(path)
      end
    end

    def save(path)
      info "saving '#{path}'"
      File.open(path, 'w+') do |f|
        f.write(YAML.dump([@volumes, @in_transaction, @pending_changes]))
      end
    end

    def load(path)
      info "loading '#{path}'"
      if File.exist?(path)
        @volumes, @in_transaction, @pending_changes = YAML.load_file(path)
      end
    end

    def init
      @volumes = Set.new
      @pending_changes = false
      save(@path)
    end

    def load_or_init
      if in_transaction?
        load @pending_path

      elsif File.exist? @path
        load @path

      else
        init
      end
    end
  end

  class VolumeManager
    attr_reader :metadata

    # FIXME: remove default arg
    def initialize(metadata = YAMLMetadata.new)
      @metadata = metadata
    end

    #--------------------------------

    def wipe
      @metadata.wipe
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
      mark_pending

      new_volume
    end

    def snap_volume(name, opts = Hash.new)
      parent = volume_by_name(name)
      new_volume = Volume.new(VolumeId.new, parent_id: parent.volume_id)

      @metadata.volumes << new_volume
      mark_pending

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
      raise RuntimeError, "unknown volume '#{name}'" unless vol
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

    def mark_pending
      @metadata.pending_changes = true
    end
  end
end
