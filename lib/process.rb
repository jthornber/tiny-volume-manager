require 'lib/dry_run'
require 'lib/log'

#----------------------------------------------------------------

module ProcessControl
  def ProcessControl.really_run(*cmd)
    cmd_line = cmd.join(' ')
    debug "executing: '#{cmd_line}'"

    cld_in = IO.pipe
    cld_out = IO.pipe
    cld_err = IO.pipe

    pid = fork do
      cld_in[1].close
      cld_out[0].close
      cld_err[0].close

      STDIN.reopen(cld_in[0])
      STDOUT.reopen(cld_out[1])
      STDERR.reopen(cld_err[1])

      exec(cmd_line)
    end

    # we're not sending any input yet
    cld_in[0].close
    cld_in[1].close

    cld_out[1].close
    cld_err[1].close

    stdout_output = Array.new
    stderr_output = Array.new

    # kick off threads to gather output
    stdout_tid = Thread.new(cld_out[0]) do |p|
      while line = p.gets
        stdout_output << line.chomp
      end
      p.close
    end

    stderr_tid = Thread.new(cld_err[0]) do |p|
      while line = p.gets
        stderr_output << line.chomp
      end
      p.close
    end

    stdout_tid.join
    stderr_tid.join

    pid, exit_status = Process.wait2(pid)

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
