module TVM
  class Volume
    attr_reader :volume_id, :parent_id, :create_time
    attr_accessor :name

    def initialize(id, opts = Hash.new)
      @volume_id = id
      @name = opts.fetch(:name, nil)
      @parent_id = opts.fetch(:parent_id, nil)
      @create_time = opts.fetch(:create_time, Time.now)
    end
  end
end
