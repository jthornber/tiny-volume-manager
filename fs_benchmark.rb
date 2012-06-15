#!/usr/bin/env ruby

require 'config'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/git'
require 'lib/status'
require 'lib/tags'
require 'lib/thinp-test'
require 'lib/xml_format'

#----------------------------------------------------------------

# Repeatedly runs iozone, taking a new snap and dropping the old
# between each run.
class FSBench < ThinpTestCase
  include Tags
  include Utils
  include XMLFormat

  def timed_block(desc, &block)
    lambda {report_time(desc, &block)}
  end

  def bonnie(dir = '.')
    ProcessControl::run("bonnie++ -d #{dir} -u root -s 2048")
  end

  TAGS = %w(v2.6.12 v2.6.18 v2.6.22 v2.6.26 v2.6.30 v2.6.34 v2.6.37 v3.2)

  def git_extract
    repo = Git.clone('/root/linux-github', 'linux')

    repo.in_repo do
      TAGS.each do |tag|
        report_time("checking out #{tag}") do
          repo.checkout(tag)
        end
      end
    end

    repo.delete
  end

  def with_fs(dev, fs_type)
    puts "formatting ..."
    fs = FS::file_system(fs_type, dev)
    fs.format

    fs.with_mount('./bench_mnt') do
      Dir.chdir('./bench_mnt') do
        yield
      end
    end
  end

  def dump_metadata(pool, dev, path)
    pool.message(0, "reserve_metadata_snap")
    status = PoolStatus.new(pool)
    ProcessControl::run("thin_dump -m #{status.held_root} #{dev} > #{path}")
    pool.message(0, "release_metadata_snap")
  end

  def raw_test(&block)
    with_fs(@data_dev, :xfs, &timed_block("raw test", &block))
  end

  def thin_test(&block)
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @size / 2, 0) do |thin|
        with_fs(thin, :xfs, &timed_block("thin test", &block))
      end
    end
  end

  def rolling_snap_test(&block)
    with_standard_pool(@size) do |pool|
      with_new_thin(pool, @size / 2, 0) do |thin|
        body = lambda do
          report_time("rolling snap") do
            block.call(pool, thin)
          end
        end

        with_fs(thin, :xfs) do
          report_time("unprovisioned", &body)

          thin.pause {pool.message(0, "create_snap 1 0")}

          report_time("re-running with snap", &body)
          report_time("broken sharing", &body)

          pool.message(0, "delete 1")
          thin.pause do
            pool.message(0, "create_snap 1 0")
          end

          report_time("and again, with a different snap", &body)
          report_time("broken sharing", &body)
        end
      end
    end
  end

  def test_bonnie_raw_device
    raw_test(&:bonnie)
  end

  def test_bonnie_thin
    thin_test(&:bonnie)
  end

  def test_bonnie_rolling_snap
    dir = Dir.pwd
    n = 0

    body = lambda do |pool, thin|
      bonnie
      dump_metadata(pool, @metadata_dev, "#{dir}/bonnie_#{n}.xml");
      n += 1
    end

    rolling_snap_test(&body)
  end

  def test_git_extract_raw
    raw_test {git_extract}
  end

  def test_git_extract_thin
    thin_test {git_extract}
  end

  def test_git_extract_rolling_snap
    dir = Dir.pwd
    n = 0

    body = lambda do |pool, thin|
      git_extract
      dump_metadata(pool, @metadata_dev, "#{dir}/git_extract_#{n}.xml");
      n += 1
    end

    rolling_snap_test(&body)
  end
end
