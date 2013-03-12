  def test_git_extract_bcache_quick
    stack = BcacheStack.new(@dm, @metadata_dev, @data_dev, :cache_size => meg(256))
    stack.activate do |cache|
      git_prepare(cache, :ext4)
      git_extract(cache, :ext4, TAGS[0..5])
    end
  end

