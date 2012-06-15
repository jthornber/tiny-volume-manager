require 'config'
require 'lib/git'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/tags'
require 'lib/thinp-test'

#----------------------------------------------------------------

class CacheTests < ThinpTestCase
  include Tags
  include Utils

  def setup
    super
    @data_block_size = 128
  end

  def _test_dt_works
    with_standard_cache do |cache|
      dt_device(cache)
    end
  end

  def _test_dd_benchmark
    with_standard_cache do |cache|
      wipe_device(cache)
    end
  end

  TAGS = %w(v2.6.12 v2.6.13 v2.6.14 v2.6.15 v2.6.16 v2.6.17 v2.6.18 v2.6.19
            v2.6.20 v2.6.21 v2.6.22 v2.6.23 v2.6.24 v2.6.25 v2.6.26 v2.6.27 v2.6.28
            v2.6.29 v2.6.30 v2.6.31 v2.6.32 v2.6.33 v2.6.34 v2.6.35 v2.6.36 v2.6.37
            v2.6.38 v2.6.39 v3.0 v3.1 v3.2)

  def do_git_prepare(dev, fs_type)
    fs_type = :ext4

    fs = FS::file_system(fs_type, dev)
    STDERR.puts "formatting ..."
    fs.format

    fs.with_mount('./kernel_builds') do
      Dir.chdir('./kernel_builds') do
        STDERR.puts "getting repo ..."
        repo = Git.clone('/root/linux-github', 'linux')
      end
    end
  end

  def do_git_extract(dev, fs_type)
    fs_type = :ext4

    fs = FS::file_system(fs_type, dev)
    fs.with_mount('./kernel_builds') do
      Dir.chdir('./kernel_builds') do
        repo = Git.new('linux')

        repo.in_repo do
          report_time("extract all versions") do
            TAGS.each do |tag|
              STDERR.puts "Checking out #{tag} ..."
              report_time("checking out #{tag}") do
                repo.checkout(tag)
                ProcessControl.run('sync')
              end
            end
          end
        end
      end
    end
  end

  def test_git_extract_cache
    do_git_prepare(@data_dev, :ext4)

    with_standard_cache do |cache|
      do_git_extract(cache, :ext4)
    end
  end

  def test_git_extract_linear
    with_standard_linear do |linear|
      do_git_prepare(linear, :ext4)
      do_git_extract(linear, :ext4)
    end
  end
end
