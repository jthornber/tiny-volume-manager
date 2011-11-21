# The thin_dump and thin_restore use an xml based external
# representation of the metadata.  This module gives the test suite
# access to this xml data.

#----------------------------------------------------------------

require 'rexml/document'
require 'rexml/streamlistener'

module XMLFormat
  include REXML

  SUPERBLOCK_FIELDS = [[:uuid, :string],
                       [:time, :int],
                       [:transaction, :int],
                       [:data_block_size, :int]]

  MAPPING_FIELDS = [[:origin_begin, :int],
                    [:data_begin, :int],
                    [:length, :int],
                    [:time, :int]]

  DEVICE_FIELDS = [[:dev_id, :int],
                   [:mapped_blocks, :int],
                   [:transaction, :int],
                   [:creation_time, :int],
                   [:snap_time, :int],
                   [:mappings, :object]]

  def self.field_names(flds)
    flds.map {|p| p[0]}
  end

  Superblock = Struct.new(*field_names(SUPERBLOCK_FIELDS))
  Mapping = Struct.new(*field_names(MAPPING_FIELDS))
  Device = Struct.new(*field_names(DEVICE_FIELDS))
  Metadata = Struct.new(:superblock, :devices)

  class Listener
    include REXML::StreamListener

    attr_reader :metadata

    def initialize
      @metadata = Metadata.new(nil, Array.new)
    end

    def to_hash(pairs)
      r = Hash.new
      pairs.each do |p|
        r[p[0].intern] = p[1]
      end
      r
    end

    def get_fields(attr, flds)
      flds.map do |n,t|
        case t
        when :int
          attr[n].to_i

        when :string
          attr[n]

        when :object
          attr[n]

        else
          raise RuntimeError, "unknown field type"
        end
      end
    end

    def tag_start(tag, args)
      attr = to_hash(args)

      case tag
      when 'superblock'
        @metadata.superblock = Superblock.new(*get_fields(attr, SUPERBLOCK_FIELDS))

      when 'device'
        attr[:mappings] = Array.new
        @current_device = Device.new(*get_fields(attr, DEVICE_FIELDS))
        @metadata.devices << @current_device

      when 'single_mapping'
        @current_device.mappings << Mapping.new(attr[:origin_block], attr[:data_block], 1)

      when 'range_mapping'
        @current_device.mappings << Mapping.new(*get_fields(attr, MAPPING_FIELDS))

      else
        puts "unhandled tag '#{tag} #{attr.map {|x| x.inspect}.join(', ')}'"
      end
    end

    def tag_end(tag)
    end

    def text(data)
      return if data =~ /^\w*$/ # ignore whitespace
      abbrev = data[0..40] + (data.length > 40 ? "..." : "")
      puts "  text    :    #{abbrev.inspect}"
    end
  end

  def read_xml(io)
    l = Listener.new
    Document.parse_stream(io, l)
    l.metadata
  end

  class Emitter
    def initialize(out)
      @out = out
      @indent = 0
    end

    def emit_tag(obj, tag, *fields, &block)
      expanded = fields.map {|fld| "#{fld}=\"#{obj.send(fld)}\""}
      if block.nil?
        emit_line "<#{tag} #{expanded.join(' ')}/>"
      else
        emit_line "<#{tag} #{expanded.join(' ')}>"
        push
        yield unless block.nil?
        pop
        emit_line "</#{tag}>"
      end
    end

    def emit_line(str)
      @out.puts((' ' * @indent) + str)
    end

    def push
      @indent += 2
    end

    def pop
      @indent -= 2
    end
  end

  def emit_superblock(e, sb, &block)
    e.emit_tag(sb, 'superblock', :uuid, :time, :transaction, :data_block_size, &block)
  end

  def emit_device(e, dev, &block)
    e.emit_tag(dev, 'device', :dev_id, :mapped_blocks, :transaction, :creation_time, :snap_time, &block)
  end

  def emit_mapping(e, m)
    if m.length == 1
      e.emit_line("<single_mapping origin_block=\"#{m.origin_begin}\" data_block=\"#{m.data_begin}\" time=\"#{m.time}\"/>")
    else
      e.emit_tag(m, 'range_mapping', :origin_begin, :data_begin, :length, :time)
    end
  end

  def write_xml(metadata, io)
    e = Emitter.new(io)

    emit_superblock(e, metadata.superblock) do
      metadata.devices.each do |dev|
        emit_device(e, dev) do
          dev.mappings.each do |m|
            emit_mapping(e, m)
          end
        end
      end
    end
  end
end

#----------------------------------------------------------------
