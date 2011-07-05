# Edit this file to add your setup

module Config
  CONFIGS = {
    'vm2' =>
    { :metadata_dev => '/dev/sdc',
      :data_dev => '/dev/sdd'
    },
    'ubuntu' =>
    { :metadata_dev => 'metadata_dev',
      :data_dev => 'data_dev'
    }
  }

  def Config.get_config
    host = `hostname --fqdn`.chomp
    if CONFIGS.has_key?(host)
      CONFIGS[host]
    else
      raise RuntimeError, "unknown host, set up your config in config.rb"
    end
  end
end


