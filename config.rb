# Edit this file to add your setup

module Config
  CONFIGS = {
    # ejt's machines
    'vm2' =>
    { :metadata_dev => '/dev/sdc',
      :data_dev => '/dev/sdd'
    },

    'vm-debian-6-x86-64' =>
    { :metadata_dev => '/dev/sdc',
      :data_dev => '/dev/sdd'
    },

    'vm-debian-32' =>
    { :metadata_dev => '/dev/sdc',
      :data_dev => '/dev/sdd'
    },

    'ubuntu' =>
    { :metadata_dev => 'metadata_dev',
      :data_dev => 'data_dev'
    },

    # others ...
    's6500.ww.redhat.com' =>
    { :metadata_dev => '/dev/loop1',
      :metadata_size => 32768,
      :data_dev => '/dev/loop0',
      :data_size => 6696048,
      :volume_size => 1097152,
      :data_block_size => 128,
      :low_water_mark => 1
    },


    'a4.ww.redhat.com' =>
    { :metadata_dev => '/dev/tst_fc_enc/metadata',
      :metadata_size => 32768,
      :data_dev => '/dev/tst_fc_enc/pool',
      :data_size => 838877184,
      :volume_size => 70377, # 2097152,
      :data_block_size => 524288,
      :low_water_mark => 5
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
