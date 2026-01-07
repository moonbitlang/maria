///|
/// Long-lived supervisor that exposes Maria's REST API and fans out requests
/// to per-workspace tasks. `Daemon` owns the HTTP server, process manager, and
/// bookkeeping maps for active tasks.
struct Daemon {
  clock : &@clock.Clock
  models : @model.Loader
  uuid : @uuid.Generator
  process : @spawn.Manager
  /// Maps from working directory to a running task.
  by_cwd : Map[String, TaskLock]
  by_id : Map[@uuid.Uuid, Task]
  rqs : Map[String, @aqueue.Queue[@server.RegisterRequest]]
  exec_path : String
  httpx : @httpx.Server
  port : Int
  events : @broadcast.Broadcast[Event]
  serve : String
  conversations : @conversation.Manager
  home : String
}

///|
/// Returns the actual TCP port the daemon bound to after the HTTP server is
/// created. This is useful when callers asked for `--port 0` (ephemeral port)
/// and need to propagate the assigned value.
pub fn Daemon::port(self : Daemon) -> Int {
  self.port
}

///|
priv enum Event {
  StatusChange(@uuid.Uuid)
}

///|
/// Constructs a daemon instance, validates the executable path, optionally
/// acquires the `~/.moonagent/daemon.json` lock, and binds the HTTP server.
/// Returns `None` when another daemon already holds the lock.
pub async fn Daemon::new(
  uuid? : @uuid.Generator,
  exec_path~ : String,
  port~ : Int,
  serve~ : String,
  cwd? : StringView,
  home? : StringView,
  lock? : Bool = true,
) -> Daemon? {
  let home = match home {
    None => @os.home()
    Some(home) => home.to_string()
  }
  // Validate exec_path points to an existing file.
  if !@fsx.exists(exec_path) {
    fail("Exec path does not exist: \{exec_path}")
  }
  let exec_path = @fsx.resolve(exec_path) catch {
    error => fail("Failed to resolve exec path '\{exec_path}': \{error}")
  }
  let info_file = if lock {
    // Grab daemon lock file
    guard lock_daemon_file(home~) is Some(info_file) else {
      println(
        "[INFO] Another Maria daemon is already running for home '\{home}'. Exiting.",
      )
      return None
    }
    Some(info_file)
  } else {
    None
  }
  // Listen on port
  let httpx_server = @httpx.Server::new("[::1]", port, reuse_addr=true)
  let port = httpx_server.port()
  if info_file is Some(info_file) {
    @fsx.truncate(info_file, 0)
    info_file.write(
      DaemonInfo::{ version: @buildinfo.version, port, pid: @spawn.getpid() }
      .to_json()
      .stringify(),
    )
  }
  println(
    "[INFO] Starting HTTP server on port \{port} (version \{@buildinfo.version})...",
  )
  println("[INFO] Visit http://localhost:\{port}/")
  let uuid = match uuid {
    Some(uuid) => uuid
    None => @uuid.generator(@rand.chacha8())
  }
  let cwd = match cwd {
    Some(cwd) => cwd.to_string()
    None => @os.cwd()
  }
  let daemon = Daemon::{
    clock: @clock.epoch,
    models: @model.Loader::new(home=@os.home(), cwd~),
    uuid,
    process: @spawn.Manager::new(cwd~),
    by_cwd: {},
    by_id: {},
    rqs: {},
    exec_path,
    httpx: httpx_server,
    port,
    events: @broadcast.Broadcast::new(),
    serve,
    conversations: @conversation.Manager::new(home~, uuid~),
    home,
  }
  daemon.load_stopped()
  Some(daemon)
}
