module TVMWorld
  include TVM

  # FIXME: duplication
  def metadata_path
    "./volumes.yaml"
  end

  def vm
    @vm ||= VolumeManager.new
  end
end

World(TVMWorld)
