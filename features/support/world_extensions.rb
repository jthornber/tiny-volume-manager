require 'lib/disk-units'

module TVMWorld
  include TVM
  include DiskUnits

  # FIXME: duplication
  def metadata_path
    "./volumes.yaml"
  end

  def metadata
    @metadata ||= YAMLMetadata.new(metadata_path)
  end

  def vm
    @vm ||= VolumeManager.new(metadata)
  end

  def reload_metadata
    @metadata = YAMLMetadata.new(metadata_path)
    @vm = VolumeManager.new(metadata)
  end
end

World(TVMWorld)
