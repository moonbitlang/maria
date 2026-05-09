///|
let systemd_unit_name : String = "maria.service"

///|
fn systemd_unit_path(home : String) -> String {
  home
  |> @pathx.join(".config")
  |> @pathx.join("systemd")
  |> @pathx.join("user")
  |> @pathx.join(systemd_unit_name)
}

///|
fn generate_unit(config : ServiceConfig) -> String {
  let lines : Array[String] = []
  lines.push("[Unit]")
  lines.push("Description=Maria AI Coding Agent Daemon")
  lines.push("")
  lines.push("[Service]")
  lines.push(
    "ExecStart=\{config.exec_path} daemon --port \{config.port} --serve \{config.serve} --managed",
  )
  lines.push("Restart=on-failure")
  lines.push("RestartSec=2")
  lines.push("Environment=HOME=\{config.home}")
  lines.push("")
  lines.push("[Install]")
  lines.push("WantedBy=default.target")
  lines.join("\n") + "\n"
}

///|
async fn systemd_install(config : ServiceConfig) -> Unit {
  let unit_path = systemd_unit_path(config.home)
  let unit_dir = @pathx.dirname(unit_path)
  @fsx.make_directory(unit_dir, recursive=true, exists_ok=true)
  @fsx.make_directory(
    config.home |> @pathx.join(".moonagent"),
    recursive=true,
    exists_ok=true,
  )
  let content = generate_unit(config)
  @fsx.write_to_file(unit_path, content)
  logger.info("Wrote systemd unit to \{unit_path}")
  ignore(@spawn.spawn("systemctl", ["--user", "daemon-reload"]))
  ignore(@spawn.spawn("systemctl", ["--user", "enable", systemd_unit_name]))
  logger.info("Service enabled via systemctl.")
}

///|
async fn systemd_uninstall(config : ServiceConfig) -> Unit {
  let unit_path = systemd_unit_path(config.home)
  try {
    ignore(
      @spawn.spawn("systemctl", [
        "--user", "disable", "--now", systemd_unit_name,
      ]),
    )
    logger.info("Service disabled and stopped via systemctl.")
  } catch {
    _ => logger.warn("Could not disable service (may not be loaded).")
  }
  if @fsx.exists(unit_path) {
    @fsx.remove(unit_path)
    logger.info("Removed unit file at \{unit_path}")
  }
  ignore(@spawn.spawn("systemctl", ["--user", "daemon-reload"])) catch {
    _ => ()
  }
}

///|
async fn systemd_ensure_running(config : ServiceConfig) -> Int {
  let unit_path = systemd_unit_path(config.home)
  // Install if not already installed
  if !@fsx.exists(unit_path) {
    systemd_install(config)
  }
  ignore(@spawn.spawn("systemctl", ["--user", "start", systemd_unit_name])) catch {
    error => {
      logger.error("Failed to start service: \{error}")
      raise error
    }
  }
  wait_for_daemon(config.home, 60_000)
}

///|
async fn systemd_stop(config : ServiceConfig) -> Unit {
  try {
    ignore(@spawn.spawn("systemctl", ["--user", "stop", systemd_unit_name]))
    logger.info("Stopped daemon via systemctl.")
  } catch {
    _ =>
      // Fallback: direct shutdown via HTTP
      detach_stop(config)
  }
}

///|
async fn systemd_restart(config : ServiceConfig) -> Unit {
  let unit_path = systemd_unit_path(config.home)
  // Update unit file in case config changed
  let content = generate_unit(config)
  @fsx.write_to_file(unit_path, content)
  ignore(@spawn.spawn("systemctl", ["--user", "daemon-reload"])) catch {
    _ => ()
  }
  try {
    ignore(@spawn.spawn("systemctl", ["--user", "restart", systemd_unit_name]))
    logger.info("Restarted daemon via systemctl.")
  } catch {
    _ => {
      systemd_stop(config)
      @async.sleep(1_000)
      ignore(systemd_ensure_running(config))
    }
  }
}
