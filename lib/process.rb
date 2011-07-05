require 'lib/log'

#----------------------------------------------------------------

module ProcessControl
  $dry_run = true

  def ProcessControl.run(*cmd)
    cmd_line = cmd.join(' ')
    
    debug "executing: '#{cmd_line}'"
    if !$dry_run
      fork do
        exec(cmd_line);
      end
      Process.wait
    end
  end

  def ProcessControl.sleep(duration)
    if !$dry_run
      Kernel.sleep(duration)
    end
  end
end

#----------------------------------------------------------------
