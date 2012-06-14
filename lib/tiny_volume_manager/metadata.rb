require 'rubygems'
require 'active_record'

# I'm having trouble with the gem version, so copied file to debug
require 'lib/acts_as_tree'

require 'logger'

#----------------------------------------------------------------

module Metadata
  include ActiveRecord

  # FIXME: separate interface from concrete implementation
  class MetadataStore
    # FIXME: We should allow people to pass their own active record
    # connection in, rather than forcing them to use sqlite
    def initialize(sqlite_path)
      setup_logging
      connect(sqlite_path)
      setup_schema
    end

    def setup_logging
      ActiveRecord::Base.logger = Logger.new(STDERR)
    end

    def connect(sqlite_path)
      connect_details = {
        :adapter => 'sqlite3',
        :database => sqlite_path
      }

      @db = ActiveRecord::Base.establish_connection(connect_details)
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
        
        # ie. a portion of a physical volume
        create_table :identity_targets do |t|
          # no data
        end

        create_table :striped_targets do |t|
          t.column :nr_stripes, :integer
        end
      end
    end    
  end

  class Volume < Base
    has_many :segments
  end

  class Segment < Base
    belongs_to :volume
    acts_as_tree :order => :offset
    belongs_to :target, :polymorphic => true
  end

  class IdentityTarget < Base
    has_one :segment, :as => :target
  end

  class StripedTarget < Base
    has_one :segment, :as => :target
  end
end

#----------------------------------------------------------------
