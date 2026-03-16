///|
/// Backend kind — identifies how the daemon process is managed.
/// Used as the `managed_by` field in `DaemonInfo` / `daemon.json`.
pub(all) enum Backend {
  Launchd
  Systemd
  Detach
} derive(Show, Eq)

///|
pub impl ToJson for Backend with to_json(self) {
  match self {
    Launchd => "launchd"
    Systemd => "systemd"
    Detach => "detach"
  }
}

///|
pub impl @json.FromJson for Backend with from_json(
  json : Json,
  _path : @json.JsonPath,
) -> Backend raise {
  match json {
    String("launchd") => Launchd
    String("systemd") => Systemd
    _ => Detach
  }
}

///|
pub enum ServiceStatus {
  Running(port~ : Int, pid~ : Int, version~ : String)
  Stopped
  NotInstalled
} derive(Show)

///|
pub(all) struct ServiceConfig {
  exec_path : String
  port : Int
  serve : String
  home : String
}

///|
/// The service manager enum. Each variant wraps a `ServiceConfig` and
/// dispatches lifecycle methods via pattern matching.
pub(all) enum ServiceManager {
  Launchd(ServiceConfig)
  Systemd(ServiceConfig)
  Detach(ServiceConfig)
}

///|
pub fn ServiceManager::backend(self : ServiceManager) -> Backend {
  match self {
    Launchd(_) => Backend::Launchd
    Systemd(_) => Backend::Systemd
    Detach(_) => Backend::Detach
  }
}

///|
pub fn ServiceManager::config(self : ServiceManager) -> ServiceConfig {
  match self {
    Launchd(c) | Systemd(c) | Detach(c) => c
  }
}

///|
/// Detect the platform and return the appropriate `ServiceManager`.
pub fn detect(config : ServiceConfig) -> ServiceManager {
  match @os.platform() {
    MacOS => Launchd(config)
    Linux => Systemd(config)
    Unknown => Detach(config)
  }
}
