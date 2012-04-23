# Edit this file to add your setup

module Config
  # You can now configure different profiles for a machine.  Add the
  # profile name after a colon to the hash key, and then run with the
  # -p switch.
  # eg,
  #   ./run_tests --profile mix -t /Basic/

  CONFIGS = {
    # ejt's machines
    'debian-vm2.lambda.co.uk' => {
      :metadata_dev => '/dev/vdb',
      :data_dev => '/dev/vdc',
      :mass_fs_tests_parallel_runs => 3,
    },

    'debian-vm2.lambda.co.uk:mix' => {
      :metadata_dev => '/dev/vdb', # SSD
      :data_dev => '/dev/vde',
      :data_size => 1097152 * 2 * 10,
      :volume_size => 1097152 * 2,
      :mass_fs_tests_parallel_runs => 3,
    },

    'debian-vm2.lambda.co.uk:spindle' => {
      :metadata_dev => '/dev/vdb', # SSD
      :data_dev => '/dev/vde',
      :data_size => 1097152 * 2 * 10,
      :volume_size => 1097152 * 2,
      :mass_fs_tests_parallel_runs => 3
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
    { :metadata_dev => '/dev/tst/metadata',
      :metadata_size => 32768,
      :data_dev => '/dev/tst/pool',
      :data_size => 419463168,
      :volume_size => 70377, # 2097152,
      :data_block_size => 524288,
      :low_water_mark => 5,
      :mass_fs_tests_parallel_runs => 128
    }

  }

  def Config.get_config
    host = `hostname --fqdn`.chomp
    if CONFIGS.has_key?(host)
      host = "#{host}:#{$profile}" if $profile
      CONFIGS[host]
    else
      raise RuntimeError, "unknown host, set up your config in config.rb"
    end
  end
end
