require 'config'
require 'lib/git'
require 'lib/log'
require 'lib/utils'
require 'lib/fs'
require 'lib/tags'
require 'lib/thinp-test'

require 'pp'

#----------------------------------------------------------------

class CacheTests < ThinpTestCase
  include Tags
  include Utils

  def setup
    super
    @data_block_size = 2048
  end

  def drop_caches
    ProcessControl.run('echo 3 > /proc/sys/vm/drop_caches')
  end

  def _test_dt_works
    with_standard_cache(:format => true) do |cache|
      dt_device(cache)
    end
  end

  def _test_dd_benchmark
    with_standard_cache(:format => true) do |cache|
      wipe_device(cache)
    end
  end

  def do_fio(dev, fs_type)
    fs = FS::file_system(fs_type, dev)
    fs.format

    fs.with_mount('./fio_test', :discard => true) do
      Dir.chdir('./fio_test') do
        ProcessControl.run("fio ../tests/cache/fio.config")
      end
    end
  end

  TAGS = %w(v2.6.12 v2.6.13 v2.6.14 v2.6.15 v2.6.16 v2.6.17 v2.6.18 v2.6.19
            v2.6.20 v2.6.21 v2.6.22 v2.6.23 v2.6.24 v2.6.25 v2.6.26 v2.6.27 v2.6.28
            v2.6.29 v2.6.30 v2.6.31 v2.6.32 v2.6.33 v2.6.34 v2.6.35 v2.6.36 v2.6.37
            v2.6.38 v2.6.39 v3.0 v3.1 v3.2)

  def do_git_prepare_(dev, fs_type)
    fs = FS::file_system(fs_type, dev)
    STDERR.puts "formatting ..."
    fs.format

    fs.with_mount('./kernel_builds', :discard => true) do
      Dir.chdir('./kernel_builds') do
        STDERR.puts "getting repo ..."
        repo = Git.clone('/root/linux-github', 'linux')
      end
    end
  end

  def do_git_prepare(dev, fs_type)
    report_time("git_prepare", STDERR) {do_git_prepare_(dev, fs_type)}
  end

  def do_git_extract(dev, fs_type, tags = TAGS)
    fs_type = :ext4

    fs = FS::file_system(fs_type, dev)
    fs.with_mount('./kernel_builds', :discard => true) do
      Dir.chdir('./kernel_builds') do
        repo = Git.new('linux')

        repo.in_repo do
          report_time("extract all versions", STDERR) do
            tags.each do |tag|
              STDERR.puts "Checking out #{tag} ..."
              report_time("checking out #{tag}") do
                repo.checkout(tag)
                ProcessControl.run('sync')
                drop_caches
              end
            end
          end
        end
      end
    end
  end

  def do_format(dev, fs_type)
    fs = FS::file_system(fs_type, dev)

    report_time("formatting", STDERR) do
      fs.format
    end

    report_time("mount/umount/fsck", STDERR) do
      fs.with_mount('./test_fs', :discard => true) do
      end
    end
  end

  def do_bonnie(dev, fs_type)
    fs = FS::file_system(fs_type, dev)
    fs.format
    fs.with_mount('./test_fs', :discard => true) do
      Dir.chdir('./test_fs') do
        report_time("bonnie++") do
          ProcessControl::run("bonnie++ -d . -u root -s 1024")
        end
      end
    end
  end

  def test_git_extract_cache_quick
    meg = 2048

    with_standard_cache(:cache_size => 1024 * meg,
                        :format => true,
                        :block_size => 512,
                        :policy => 'mq'
                        #:data_size => 1400 * meg
                        ) do |cache|
      do_git_prepare(cache, :ext4)
      do_git_extract(cache, :ext4, TAGS[0..5])
    end
  end

  def test_git_extract_cache
    meg = 2048

    with_standard_cache(:format => true, :block_size => 512) do |cache|
      do_git_prepare(cache, :ext4)
      do_git_extract(cache, :ext4)
    end
  end

  def test_cache_sizing_effect
    meg = 2048
    cache_sizes = [64,128,192,256,320,384,448,512,576,640,704,768,832,896,960,1024,1088,1152,1216,1280,1344,1408]

    cache_sizes.each do |size|
      with_standard_cache(:cache_size => size * meg,
                          :format => true,
                          :block_size => 512,
                          :data_size => 1408 * meg) do |cache|
        report_time("extract_log_test with cache size #{size}M") do
          do_git_prepare(cache, :ext4)
          do_git_extract(cache, :ext4, TAGS[0..5])
        end
      end
    end
  end

  def test_git_extract_linear
    with_standard_linear do |linear|
      do_git_prepare(linear, :ext4)
      do_git_extract(linear, :ext4)
    end
  end

  def test_git_extract_linear_quick
    with_standard_linear do |linear|
      do_git_prepare(linear, :ext4)
      do_git_extract(linear, :ext4, TAGS[0..5])
    end
  end

  def test_fio_linear
    with_standard_linear do |linear|
      do_fio(linear, :ext4)
    end
  end

  def test_fio_cache
    meg = 2048

    with_standard_cache(:cache_size => 1024 * meg,
                        :format => true,
                        :block_size => 512,
                        :data_size => 1024 * meg,
                        :policy => 'mq') do |cache|
      do_fio(cache, :ext4)
    end
  end

  def test_format_linear
    with_standard_linear do |linear|
      do_format(linear, :ext4)
    end
  end

  def test_format_cache
    with_standard_cache(:format => true, :policy => 'lru') do |cache|
      do_format(cache, :ext4)
    end
  end

  def test_bonnie_linear
    with_standard_linear do |linear|
      do_bonnie(linear, :ext4)
    end
  end

  def test_bonnie_cache
    meg = 2048

    with_standard_cache(:cache_size => 256 * meg,
                        :format => true,
                        :block_size => 512,
                        :policy => 'mkfs') do |cache|
      do_bonnie(cache, :ext4)
    end
  end

  # Checks we can remount an fs
  def test_metadata_persists
    with_standard_cache(:format => true) do |cache|
      fs = FS::file_system(:ext4, cache)
      fs.format
      fs.with_mount('./test_fs') do
        drop_caches
      end
    end


    with_standard_cache do |cache|
      fs = FS::file_system(:ext4, cache)
      fs.with_mount('./test_fs') do
      end
    end
  end

  def test_suspend_resume
    with_standard_cache(:format => true) do |cache|
      do_git_prepare(cache, :ext4)

      3.times do
        report_time("suspend/resume", STDERR) do
          cache.pause {}
        end
      end
    end
  end

  def test_table_reload
    with_standard_cache(:format => true) do |cache|
      table = cache.active_table

      do_git_prepare(cache, :ext4)

      cache.pause do
        cache.load(table)
      end
    end
  end

  def test_table_reload_changed_policy
    with_standard_cache(:format => true, :policy => 'mq') do |cache|
      table = cache.active_table

      tid = Thread.new(cache) do
        do_git_prepare(cache, :ext4)
      end

      use_mq = false

      while tid.alive?
        sleep 5
        cache.pause do
          table.targets[0].args[4] = use_mq ? 'mq' : 'mkfs'
          cache.load(table)
          use_mq = !use_mq
        end
      end

      tid.join
    end
  end
  
  def test_dt_cache
    with_standard_cache(:format => true, :policy => 'mq') do |cache|
      dt_device(cache)
    end
  end

  def test_unknown_policy_fails
    assert_raise(ExitError) do
      with_standard_cache(:format => true,
                          :policy => 'time_traveller') do |cache|
      end
    end
  end

  #----------------------------------------------------------------
  # SQLITE tests
  # FIXME: move to separate suite?
  #----------------------------------------------------------------

  def sql_create_table
    "CREATE TABLE t1(a INTEGER, b INTEGER, c VARCHAR(100));\n"
  end

  def sql_drop_table
    "DROP TABLE t1;\n"
  end

  def sql_begin
    "BEGIN;"
  end

  def sql_commit
    "COMMIT;"
  end

  def sql_transaction(count = nil, &block)
    sql = sql_begin
    sql += yield
    sql += sql_commit
    sql
  end

  def sql_create_inserts(count = nil, start = nil)
    count = 12500 if count.nil?
    start = 0 if start.nil?
    sql = ""

    for i in start..count
      v = rand(999999999).to_i
      s = number_to_string(v)
      sql += "INSERT INTO t1 VALUES(#{i},#{v},\'#{s}');\n"
    end

    sql
  end

  def sql_inserts_no_transaction(count = nil)
    sql_create_table +  sql_create_inserts(count)
  end

  def sql_inserts_global_transaction(count = nil)
    sql = sql_transaction do
      sql_create_table +  sql_create_inserts(count) + sql_drop_table
    end

    sql
  end

  def sql_inserts_multiple_transaction(count = nil, fraction = nil)
    count = 12500 if count.nil?
    fraction = count / 1000 if fraction.nil?

    return "" if count / fraction < 2

    sql = sql_begin + sql_create_table

    i = 0
    while i < count do
      sql += sql_transaction { sql_create_inserts(count, fraction) }
      sql += sql_commit + sql_begin
      i += fraction
    end

    sql += sql_commit
    sql
  end

  def do_sqlite_exec(sql_script)
    STDERR.puts "Running sql script..."
    Utils::with_temp_file('.sql_script') do |sql_file|
      sql_file << sql_script
      sql_file.flush
      sql_file.close

      ProcessControl.run("cp #{sql_file.path} /tmp/run_test.sql")
      ProcessControl.run("time sqlite3 test.db < #{sql_file.path}")
      ProcessControl.run("rm -fr test.db")
    end
  end

  def with_sqlite_prepare(dev, fs_type = nil, &block)
    fs_type = :ext4 if fs_type.nil?

    fs = FS::file_system(fs_type, dev)
    STDERR.puts "formatting ..."
    fs.format

    STDERR.puts "mounting ..."
    fs.with_mount('./.sql_tests', :discard => true) do
      Dir.chdir('./.sql_tests') do
	yield
      end
    end
  end

  def with_sqlite(policy = nil, records = nil, &block)
    policy = 'mq' if policy.nil?

    with_standard_cache(:format => true, :policy => policy) do |cache|
      with_sqlite_prepare(cache, :ext4) do
        STDERR.puts "\'#{policy}\' policy\n"
        report_time("#{block} with \'#{policy}\' policy...") do
	  sql = yield(records)
          do_sqlite_exec(sql)
        end
      end
    end
  end

  def test_sqlite_insert_12k_global_transaction
    @cache_policies.each do |policy|
      with_sqlite(policy, nil) { sql_inserts_global_transaction }
    end
  end

  def test_sqlite_insert_12k_multiple_transaction
    @cache_policies.each do |policy|
      with_sqlite(policy, nil) { sql_inserts_multiple_transaction }
    end
  end

  def test_sqlite_insert_12k_no_transaction
    @cache_policies.each do |policy|
      with_sqlite(policy, nil) { sql_inserts_no_transaction }
    end
  end
end
