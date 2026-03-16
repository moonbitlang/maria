///|
/// Install/register the daemon as a system service. Idempotent.
pub async fn ServiceManager::install(self : ServiceManager) -> Unit {
  match self {
    Launchd(config) => launchd_install(config)
    Systemd(config) => systemd_install(config)
    Detach(_) => logger.info("Detach mode: no service to install.")
  }
}

///|
/// Remove the service registration.
pub async fn ServiceManager::uninstall(self : ServiceManager) -> Unit {
  match self {
    Launchd(config) => launchd_uninstall(config)
    Systemd(config) => systemd_uninstall(config)
    Detach(_) => logger.info("Detach mode: no service to uninstall.")
  }
}

///|
/// Ensure the daemon is running, starting it if needed. Returns the port.
pub async fn ServiceManager::ensure_running(self : ServiceManager) -> Int {
  match self {
    Launchd(config) => launchd_ensure_running(config)
    Systemd(config) => systemd_ensure_running(config)
    Detach(config) => detach_ensure_running(config)
  }
}

///|
/// Stop a running daemon.
pub async fn ServiceManager::stop(self : ServiceManager) -> Unit {
  match self {
    Launchd(config) => launchd_stop(config)
    Systemd(config) => systemd_stop(config)
    Detach(config) => detach_stop(config)
  }
}

///|
/// Restart the daemon (e.g., for version upgrades).
pub async fn ServiceManager::restart(self : ServiceManager) -> Unit {
  match self {
    Launchd(config) => launchd_restart(config)
    Systemd(config) => systemd_restart(config)
    Detach(config) => detach_restart(config)
  }
}

///|
/// Query the current daemon status.
pub async fn ServiceManager::status(self : ServiceManager) -> ServiceStatus {
  match self {
    Launchd(config) | Systemd(config) | Detach(config) =>
      read_daemon_info(config.home)
  }
}
