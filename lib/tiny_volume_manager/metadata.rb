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
        end

#        create_table :linear_segments do |t|
#          t.column :segment_id, :integer
#          t.column :child_segment_id, :integer
#        end

#        create_table :striped_segments do |t|
#          t.column :segment_id, :integer
#        end

#        create_table :stripes do |t|
#          t.column :stripe_nr, :integer
#          t.column :striped_segment_id, :integer
#          t.column :segment_id, :integer
#        end

      end
    end    
  end

  class Volume < Base
    has_many :segments
  end

  class Segment < Base
    belongs_to :volume
    acts_as_tree :order => :offset
  end

#  class LinearSegment < Base
#    belongs_to :segment
#    belongs_to :segment, :foreign_key => :child_segment_id
#  end
end

#----------------------------------------------------------------
