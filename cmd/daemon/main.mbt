///|
using @path {type Path}

///|
priv struct DaemonInfo {
  version : @buildinfo.Version
  pid : Int
  port : Int
  managed_by : @service.Backend
}

///|
impl ToJson for DaemonInfo with to_json(self) {
  {
    "version": self.version.to_string(),
    "pid": self.pid,
    "port": self.port,
    "managed_by": self.managed_by.to_json(),
  }
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
  let managed_by : @service.Backend = match object.get("managed_by") {
    Some(v) => @json.from_json(v, path=json_path.add_key("managed_by"))
    None => @service.Backend::Detach
  }
  DaemonInfo::{ version, pid, port, managed_by }
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
  @async.with_timeout(60_000, () => {
    for ;; {
      try {
        let info_file = @fs.open(
          Path::join(home, ".moonagent").join("daemon.json").to_string(),
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
            logger.error("Waiting for daemon to start: \{error}")
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

///|
/// CLI entry point used by `moon run cmd/main -- daemon`. Parses flags,
/// optionally detaches into a background process, and otherwise starts the
/// HTTP server in the foreground.
///
/// Flags:
///   -p, --port <port>    Port to bind (default 8090)
///   -s, --serve <dir>    Directory to serve UI from
///   -d, --detach         Detach and run in background (spawn_orphan + lock)
///   --managed            Run in foreground without lock (for launchd/systemd)
///   service <cmd>        Manage OS service: install|uninstall|start|stop|restart|status
pub async fn start(args : ArrayView[String]) -> Unit {
  let mut port = 8090
  let mut serve = @os.cwd()
  let mut exec_path = None
  let mut to_detach = false
  let mut managed = false
  let mut service_cmd : String? = None
  loop args {
    ["-p" | "--port", p, .. args] => {
      port = @strconv.parse_int(p)
      continue args
    }
    ["-s" | "--serve", s, .. args] => {
      serve = if Path::is_absolute(s) {
        s
      } else {
        Path::join(@os.cwd(), s).to_string()
      }
      continue args
    }
    ["-d" | "--detach", .. args] => {
      to_detach = true
      continue args
    }
    ["--managed", .. args] => {
      managed = true
      continue args
    }
    ["service", cmd, ..] => {
      service_cmd = Some(cmd)
      break
    }
    [
      "install"
      | "uninstall"
      | "start"
      | "stop"
      | "restart"
      | "status" as cmd,
      ..,
    ] => {
      service_cmd = Some(cmd)
      break
    }
    [e, .. args] => {
      exec_path = if Path::is_absolute(e) {
        Some(e)
      } else {
        Some(Path::join(@os.cwd(), e).to_string())
      }
      continue args
    }
    [] => break
  }
  guard @model.load(home=@os.home(), cwd=@os.cwd()) is Some(_) else {
    @os.exit(-1)
  }
  let home = @os.home()
  let resolved_exec_path = if exec_path is Some(exec_path) {
    exec_path
  } else {
    @os.executable()
  }
  // When installing a service, the plist/unit must reference a real binary,
  // not the moon runtime (tcc). Detect this and resolve to the built binary.
  let service_exec_path = if exec_path is Some(_) {
    resolved_exec_path
  } else {
    let candidate = @fsx.resolve(resolved_exec_path) catch {
      _ => resolved_exec_path
    }
    if candidate.has_suffix("/tcc") || candidate.has_suffix("/tcc.exe") {
      // Running under `moon run` — use the release build binary instead
      let cwd = @os.cwd()
      let release_bin = @pathx.join(
        cwd, "_build/native/release/build/cmd/main/main.exe",
      )
      if @fsx.exists(release_bin) {
        release_bin
      } else {
        let debug_bin = @pathx.join(
          cwd, "_build/native/debug/build/cmd/main/main.exe",
        )
        if @fsx.exists(debug_bin) {
          debug_bin
        } else {
          resolved_exec_path
        }
      }
    } else {
      resolved_exec_path
    }
  }
  if service_cmd is Some(cmd) {
    let config = @service.ServiceConfig::{
      exec_path: service_exec_path,
      port,
      serve,
      home,
    }
    let mgr = @service.detect(config)
    match cmd {
      "install" => {
        mgr.install()
        logger.info("Service installed.")
      }
      "uninstall" => {
        mgr.uninstall()
        logger.info("Service uninstalled.")
      }
      "start" => {
        let port = mgr.ensure_running()
        logger.info("Daemon running on port \{port}.")
      }
      "stop" => {
        mgr.stop()
        logger.info("Daemon stopped.")
      }
      "restart" => {
        mgr.restart()
        logger.info("Daemon restarted.")
      }
      "status" => {
        let s = mgr.status()
        logger.info("Daemon status: \{s}")
      }
      _ => {
        logger.error(
          "Unknown service command: \{cmd}. Use: install|uninstall|start|stop|restart|status",
        )
        @os.exit(1)
      }
    }
  } else if to_detach {
    let pid = detach(exec_path?, port~, serve~)
    logger.info("Detached Maria daemon with PID \{pid}.")
  } else if managed {
    let managed_by : @service.Backend = match @os.platform() {
      MacOS => Launchd
      Linux => Systemd
      _ => Detach
    }
    guard Daemon::new(
        exec_path=resolved_exec_path,
        port~,
        serve~,
        home~,
        lock=false,
        managed_by~,
      )
      is Some(daemon) else {
      return
    }
    daemon.serve()
  } else {
    guard Daemon::new(exec_path=resolved_exec_path, port~, serve~, home~)
      is Some(daemon) else {
      return
    }
    daemon.serve()
  }
}
