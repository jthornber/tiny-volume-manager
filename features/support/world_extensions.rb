module TVMWorld
  include TVM

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
end

World(TVMWorld)
