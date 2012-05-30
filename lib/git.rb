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
    raise "not a git directory" unless Pathname.new("#{origin}/.git").exist?
    @origin = origin
  end

  def in_repo(&block)
    Dir.chdir(@origin, &block)
  end

  def checkout(tag)
    system("git checkout #{tag}")
  end

  def delete
    system("rm -rf #{origin}")
  end
end

#----------------------------------------------------------------
