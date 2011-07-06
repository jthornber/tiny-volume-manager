require 'lib/dry_run'
require 'lib/log'
require 'open3'

#----------------------------------------------------------------

module ProcessControl
  def ProcessControl.run_(default, *cmd)
    cmd_line = cmd.join(' ')
    
    debug "executing: '#{cmd_line}'"
    DryRun.run(default) do
      stdout_output = Array.new
      stderr_output = Array.new

      stdin, stdout, stderr = Open3.popen3(cmd_line)
      stdin.close_write

      # kick off threads to gather output
      stdout_tid = Thread.new do
        while line = stdout.gets
          stdout_output << line.chomp
        end
      end

      stderr_tid = Thread.new do
        while line = stderr.gets
          stderr_output << line.chomp
        end
      end

      stdout_tid.join
      stderr_tid.join

      if $?.exitstatus != 0
        debug "command failed with '#{$?.exitstatus}'"
        raise RuntimeError, "command failed"
      end

      if stdout_output.length > 0
        debug "stdout:\n" + stdout_output.map {|l| "    " + l}.join("\n")
      end

      if stderr_output.length > 0
        debug "stderr:\n" + stderr_output.map {|l| "    " + l}.join("\n")
      end

      stdout_output.join("\n");
    end
  end

  def ProcessControl.system(default, *cmd)
    run_(default, *cmd)
  end

  def ProcessControl.run(*cmd)
    run_('', *cmd)
  end

  def ProcessControl.sleep(duration)
    if !$dry_run
      Kernel.sleep(duration)
    end
  end
end

#----------------------------------------------------------------
