require 'lib/log'

require 'pp'

#----------------------------------------------------------------

class PoolStatus
  attr_reader :transaction_id, :used_metadata_blocks, :total_metadata_blocks, :used_data_blocks
  attr_reader :total_data_blocks, :held_root, :optionals

  def parse_held_root(txt)
    case txt
    when '-':
        nil

    else
      txt.to_i
    end
  end

  def parse_opts(txt)
    opts = Hash.new
    opts[:block_zeroing] = true
    opts[:ignore_discard] = false
    opts[:discard_passdown] = true
    opts[:read_only] = false

    m = txt.match(/\s(\d+)\s(.+)/)
    unless m.nil?
      m[2].split.each do |feature|
        case feature
        when 'skip_block_zeroing':
            opts[:block_zeroing] = false

        when 'ignore_discard':
            opts[:ignore_discard] = true

        when 'no_discard_passdown':
            opts[:discard_passdown] = false

        when 'read_only':
            opts[:read_only] = true

        else
          raise "unknown pool feature '#{feature}'"
        end
      end
    end

    pp opts

    opts
  end

  def initialize(pool)
    m = pool.status.match(/(\d+)\s(\d+)\/(\d+)\s(\d+)\/(\d+)\s(\S+)(\s.*)/)
    if m.nil?
      raise RuntimeError, "couldn't get pool status"
    end

    @transaction_id = m[1].to_i
    @used_metadata_blocks = m[2].to_i
    @total_metadata_blocks = m[3].to_i
    @used_data_blocks = m[4].to_i
    @total_data_blocks = m[5].to_i
    @held_root = parse_held_root(m[6])
    @optionals = parse_opts(m[7])
  end
end

#----------------------------------------------------------------
