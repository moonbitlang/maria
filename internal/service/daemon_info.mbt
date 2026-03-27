///|
let logger : @pino.Logger = @pino.logger("Service", @pino.Transport::console())

///|
/// Read `~/.moonagent/daemon.json` and determine the daemon's status.
///
/// Returns `Running` if the file exists, is valid JSON, and the PID is alive.
/// Returns `Stopped` if the file exists but the PID is not alive.
/// Returns `NotInstalled` if the file does not exist.
async fn read_daemon_info(home : String) -> ServiceStatus {
  let path = home |> @pathx.join(".moonagent") |> @pathx.join("daemon.json")
  if !@fsx.exists(path) {
    return NotInstalled
  }
  try {
    let text = @fsx.read_file(path)
    let json = @json.parse(text)
    guard json is { "pid": Number(pid_f, ..), "port": Number(port_f, ..), .. } else {
      return Stopped
    }
    let pid = pid_f.to_int()
    let port = port_f.to_int()
    let version = match json {
      { "version": String(v), .. } => v
      _ => "0.0.0"
    }
    // Check if the process is alive by sending signal 0
    try {
      @spawn.kill(pid, 0)
      Running(port~, pid~, version~)
    } catch {
      _ => Stopped
    }
  } catch {
    _ => Stopped
  }
}

///|
/// Poll `daemon.json` until the daemon is ready, with a timeout.
/// Returns the port once the daemon writes valid info.
async fn wait_for_daemon(home : String, timeout : Int) -> Int {
  @async.with_timeout(timeout, () => {
    for ;; {
      match read_daemon_info(home) {
        Running(port~, ..) => break port
        _ => {
          @async.sleep(500)
          continue
        }
      }
    }
  }) catch {
    @async.TimeoutError as error => {
      logger.error("Timeout waiting for daemon to start.")
      raise error
    }
    error => raise error
  }
}
