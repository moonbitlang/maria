///|
priv struct DaemonInfo {
  pid : Int
  port : Int
} derive(ToJson)

///|
/// Spawns (and optionally detaches) a Maria daemon process and waits until the
/// child writes `~/.moonagent/daemon.json`. Returns the PID recorded in that
/// file, which can belong to the new child or an already running daemon.
pub async fn detach(
  exec_path? : String,
  port? : Int,
  serve? : StringView,
) -> Int {
  let home = @os.home()
  let args = ["daemon"]
  if port is Some(port) {
    args.push("--port")
    args.push(port.to_string())
  }
  if serve is Some(serve) {
    args.push("--serve")
    args.push(serve.to_string())
  }
  if exec_path is Some(exec_path) {
    args.push(exec_path)
  }
  let pid = @process.spawn_orphan(@os.executable(), args)
  @async.with_timeout(60_000, () => for {
    try {
      let info_file = @fs.open(
        home |> @path.join(".moonagent") |> @path.join("daemon.json"),
        mode=ReadOnly,
      )
      defer info_file.close()
      if @fsx.get_lock_owner(info_file) is Some(owner) {
        if owner == pid {
          let text = info_file.read_all().text()
          let json = @json.parse(text)
          if json is { "pid": info_pid, .. } {
            let info_pid : Int = @json.from_json(info_pid)
            if info_pid == pid {
              break pid
            } else {
              break info_pid
            }
          }
        } else {
          break owner
        }
      }
      // The daemon info file is not yet locked by any process; wait and retry.
    } catch {
      error =>
        if @async.is_being_cancelled() {
          raise error
        } else {
          println("[ERROR] (Daemon) Waiting for daemon to start: \{error}")
          @async.sleep(500)
          continue
        }
    }
  }) catch {
    @async.TimeoutError as error => {
      println("[ERROR] (Daemon) Timeout waiting for daemon to start.")
      raise error
    }
    error => raise error
  }
}

///|
/// CLI entry point used by `moon run cmd/main -- daemon`. Parses flags,
/// optionally detaches into a background process, and otherwise starts the
/// HTTP server in the foreground.
pub async fn start(args : ArrayView[String]) -> Unit {
  let mut port = 8090
  let mut serve = @os.cwd()
  let mut exec_path = None
  let mut to_detach = false
  loop args {
    ["-p" | "--port", p, .. args] => {
      port = @strconv.parse_int(p)
      continue args
    }
    ["-s" | "--serve", s, .. args] => {
      serve = if @path.is_absolute(s) { s } else { @path.join(@os.cwd(), s) }
      continue args
    }
    ["-d" | "--detach", .. args] => {
      to_detach = true
      continue args
    }
    [e, .. args] => {
      exec_path = if @path.is_absolute(e) {
        Some(e)
      } else {
        Some(@path.join(@os.cwd(), e))
      }
      continue args
    }
    [] => break
  }
  guard @model.load(home=@os.home(), cwd=@os.cwd()) is Some(_) else {
    @os.exit(-1)
  }
  if to_detach {
    let pid = detach(exec_path?, port~, serve~)
    println("[INFO] (Daemon) Detached Maria daemon with PID \{pid}.")
  } else {
    let home = @os.home()
    let exec_path = if exec_path is Some(exec_path) {
      exec_path
    } else {
      @os.executable()
    }
    guard Daemon::new(exec_path~, port~, serve~, home~) is Some(daemon) else {
      return
    }
    daemon.serve()
  }
}
