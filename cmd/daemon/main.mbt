///|
priv struct DaemonInfo {
  version : @buildinfo.Version
  pid : Int
  port : Int
}

///|
impl ToJson for DaemonInfo with to_json(self) {
  { "version": self.version.to_string(), "pid": self.pid, "port": self.port }
}

///|
impl @json.FromJson for DaemonInfo with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> DaemonInfo raise {
  guard json is Json::Object(object) else {
    raise @json.JsonDecodeError((json_path, "Expected object for DaemonInfo"))
  }
  let version : String = match object.get("version") {
    Some(Null) | None => "0.0.0"
    Some(String(v)) => v
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path.add_key("version"), "Expected string for 'version' field"),
      )
  }
  let version : @buildinfo.Version = @buildinfo.Version::parse(version) catch {
    error =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("version"),
          "Invalid version string in 'version' field: " + error.to_string(),
        ),
      )
  }
  let pid = match object.get("pid") {
    Some(v) => @json.from_json(v, path=json_path.add_key("pid"))
    None =>
      raise @json.JsonDecodeError(
        (json_path, "Missing field 'pid' in DaemonInfo"),
      )
  }
  let port = match object.get("port") {
    Some(v) => @json.from_json(v, path=json_path.add_key("port"))
    None =>
      raise @json.JsonDecodeError(
        (json_path, "Missing field 'port' in DaemonInfo"),
      )
  }
  DaemonInfo::{ version, pid, port }
}

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
        home |> @pathx.join(".moonagent") |> @pathx.join("daemon.json"),
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
          // There is no pid field; wait and retry.
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
      serve = if @pathx.is_absolute(s) { s } else { @pathx.join(@os.cwd(), s) }
      continue args
    }
    ["-d" | "--detach", .. args] => {
      to_detach = true
      continue args
    }
    [e, .. args] => {
      exec_path = if @pathx.is_absolute(e) {
        Some(e)
      } else {
        Some(@pathx.join(@os.cwd(), e))
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
