require 'rubygems'
require 'active_record'

# I'm having trouble with the gem version, so copied file to debug.
# Possibly because I'm using the Debian packaged version of gem?
require 'lib/acts_as_tree'

require 'logger'

#----------------------------------------------------------------

module Metadata
  include ActiveRecord

  # FIXME: separate interface from concrete implementation
  class MetadataStore
    # FIXME: connection should be separated from schema
    def initialize(params)
      setup_logging
      connect(params)
      setup_schema
    end

    def close
    end

    def setup_logging
      ActiveRecord::Base.logger = Logger.new(File.open('sql.log', 'w'))
    end

    def connect(params)
      @db = ActiveRecord::Base.establish_connection(params)
    end

    def setup_schema
      # FIXME: check the range of the :integer fields

      ActiveRecord::Schema.define do
        create_table :volumes do |t|
          t.column :name, :string
          t.column :uuid, :string
        end

        create_table :segments, :force => true do |t|
          t.column :offset, :integer
          t.column :length, :integer
          t.column :volume_id, :integer
          t.column :parent_id, :integer
          t.column :target_id, :integer
          t.column :target_type, :string
        end

        # This covers linear targets too
        create_table :striped_targets do |t|
          t.column :nr_stripes, :integer
        end

        create_table :pool_targets do |t|
          t.column :metadata_id, :integer
          t.column :data_id, :integer
          t.column :block_size, :integer
          t.column :low_water_mark, :integer
          t.column :block_zeroing, :bool
          t.column :discard, :bool
          t.column :discard_passdown, :bool
        end

        create_table :thin_target do |t|
          t.column :pool_id, :integer
          t.column :dev_id, :integer
          t.column :origin_id, :integer
        end
      end
    end    
  end

  class Volume < Base
    has_many :segments

    def to_s
      "'#{self.name}': '#{self.uuid}'"
    end
  end

  class Segment < Base
    belongs_to :volume
    acts_as_tree :order => :offset
    belongs_to :target, :polymorphic => true

    def to_s
      "#{self.volume.name} [#{self.offset} #{self.length}]"
    end
  end

  class StripedTarget < Base
    has_one :segment, :as => :target

    def to_s
      if self.nr_stripes == 1
        "linear"
      else
        "#{self.nr_stripes} stripes"
      end
    end
  end

  class PoolTarget < Base
    has_one :segment, :as => :target
  end

  class ThinTarget < Base
    has_one :segment, :as => :target
  end
end

#----------------------------------------------------------------
