require 'lib/dry_run'
require 'lib/log'
require 'open3'

#----------------------------------------------------------------

module ProcessControl
  def ProcessControl.really_run(*cmd)
    cmd_line = cmd.join(' ')
    debug "executing: '#{cmd_line}'"

    stdout_output = Array.new
    stderr_output = Array.new

    exit_status = 255
    Open3.popen3(cmd_line) do |i, o, e, t|
      pid = t.pid
      i.close_write

      # kick off threads to gather output
      stdout_tid = Thread.new do
        while line = o.gets
          stdout_output << line.chomp
        end
      end

      stderr_tid = Thread.new do
        while line = e.gets
          stderr_output << line.chomp
        end
      end

      stdout_tid.join
      stderr_tid.join

      exit_status = t.value
    end

    if stdout_output.length > 0
      debug "stdout:\n" + stdout_output.map {|l| "    " + l}.join("\n")
    end

    if stderr_output.length > 0
      debug "stderr:\n" + stderr_output.map {|l| "    " + l}.join("\n")
    end

    if exit_status != 0
      debug "command failed with '#{exit_status}'"
      raise RuntimeError, "command failed"
    end

    stdout_output.join("\n");
  end

  def ProcessControl.run_(default, *cmd)
    DryRun.run(default) {ProcessControl.really_run(*cmd)}
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
