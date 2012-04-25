require 'lib/log'
require 'lib/process'

#----------------------------------------------------------------

class Git
  attr_reader :origin, :dir

  def self.clone(origin, dir)
    system("git clone #{origin} #{dir}")
    Git.new(dir)
  end

  def initialize(origin)
    @origin = origin
  end

  def in_repo(&block)
    Dir.chdir(@origin, &block)
  end

  def checkout(tag)
    system("git checkout #{tag}")
  end
end

#----------------------------------------------------------------
