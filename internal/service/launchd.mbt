///|
let launchd_label : String = "com.moonbitlang.maria"

///|
fn launchd_plist_path(home : String) -> String {
  home
  |> @pathx.join("Library")
  |> @pathx.join("LaunchAgents")
  |> @pathx.join("com.moonbitlang.maria.plist")
}

///|
fn launchd_domain(uid : UInt) -> String {
  "gui/\{uid}"
}

///|
fn launchd_service_target(uid : UInt) -> String {
  "gui/\{uid}/\{launchd_label}"
}

///|
fn generate_plist(config : ServiceConfig) -> String {
  let log_dir = config.home |> @pathx.join(".moonagent")
  let lines : Array[String] = []
  lines.push("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
  lines.push(
    "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
  )
  lines.push("<plist version=\"1.0\">")
  lines.push("<dict>")
  lines.push("  <key>Label</key>")
  lines.push("  <string>\{launchd_label}</string>")
  lines.push("  <key>ProgramArguments</key>")
  lines.push("  <array>")
  lines.push("    <string>\{config.exec_path}</string>")
  lines.push("    <string>daemon</string>")
  lines.push("    <string>--port</string>")
  lines.push("    <string>\{config.port}</string>")
  lines.push("    <string>--serve</string>")
  lines.push("    <string>\{config.serve}</string>")
  lines.push("    <string>--managed</string>")
  lines.push("  </array>")
  lines.push("  <key>KeepAlive</key>")
  lines.push("  <true/>")
  lines.push("  <key>RunAtLoad</key>")
  lines.push("  <true/>")
  lines.push("  <key>StandardOutPath</key>")
  lines.push("  <string>\{log_dir}/daemon.stdout.log</string>")
  lines.push("  <key>StandardErrorPath</key>")
  lines.push("  <string>\{log_dir}/daemon.stderr.log</string>")
  lines.push("</dict>")
  lines.push("</plist>")
  lines.join("\n") + "\n"
}

///|
async fn launchd_install(config : ServiceConfig) -> Unit {
  let plist_path = launchd_plist_path(config.home)
  let plist_dir = @pathx.dirname(plist_path)
  let uid = @os.getuid()
  @fsx.make_directory(plist_dir, recursive=true, exists_ok=true)
  @fsx.make_directory(
    config.home |> @pathx.join(".moonagent"),
    recursive=true,
    exists_ok=true,
  )
  // If already loaded, bootout first
  if @fsx.exists(plist_path) {
    ignore(@spawn.spawn("launchctl", ["bootout", launchd_service_target(uid)])) catch {
      _ => ()
    }
  }
  let content = generate_plist(config)
  @fsx.write_to_file(plist_path, content)
  logger.info("Wrote plist to \{plist_path}")
  // Bootstrap the service
  try {
    ignore(
      @spawn.spawn("launchctl", ["bootstrap", launchd_domain(uid), plist_path]),
    )
    logger.info("Service bootstrapped via launchctl.")
  } catch {
    _ => {
      // Fallback for older macOS
      ignore(@spawn.spawn("launchctl", ["load", "-w", plist_path]))
      logger.info("Service loaded via launchctl (legacy).")
    }
  }
}

///|
async fn launchd_uninstall(config : ServiceConfig) -> Unit {
  let plist_path = launchd_plist_path(config.home)
  let uid = @os.getuid()
  try {
    ignore(@spawn.spawn("launchctl", ["bootout", launchd_service_target(uid)]))
    logger.info("Service removed via launchctl bootout.")
  } catch {
    _ =>
      try {
        ignore(@spawn.spawn("launchctl", ["unload", plist_path]))
        logger.info("Service unloaded via launchctl (legacy).")
      } catch {
        _ => logger.warn("Could not unload service (may not be loaded).")
      }
  }
  if @fsx.exists(plist_path) {
    @fsx.remove(plist_path)
    logger.info("Removed plist at \{plist_path}")
  }
}

///|
async fn launchd_ensure_running(config : ServiceConfig) -> Int {
  let plist_path = launchd_plist_path(config.home)
  let uid = @os.getuid()
  // Install if not already installed
  if !@fsx.exists(plist_path) {
    launchd_install(config)
  }
  // Kickstart the service (starts it if not running)
  ignore(
    @spawn.spawn("launchctl", ["kickstart", "-p", launchd_service_target(uid)]),
  ) catch {
    _ =>
      // Fallback: try start
      ignore(@spawn.spawn("launchctl", ["start", launchd_label])) catch {
        error => {
          logger.error("Failed to start service: \{error}")
          raise error
        }
      }
  }
  wait_for_daemon(config.home, 60_000)
}

///|
async fn launchd_stop(config : ServiceConfig) -> Unit {
  let uid = @os.getuid()
  try {
    ignore(
      @spawn.spawn("launchctl", ["kill", "SIGTERM", launchd_service_target(uid)]),
    )
    logger.info("Sent SIGTERM to daemon via launchctl.")
  } catch {
    _ =>
      try {
        ignore(@spawn.spawn("launchctl", ["stop", launchd_label]))
        logger.info("Stopped daemon via launchctl.")
      } catch {
        _ =>
          // Fallback: direct shutdown via HTTP
          detach_stop(config)
      }
  }
}

///|
async fn launchd_restart(config : ServiceConfig) -> Unit {
  let uid = @os.getuid()
  let plist_path = launchd_plist_path(config.home)
  // Update plist in case exec_path or config changed
  let content = generate_plist(config)
  @fsx.write_to_file(plist_path, content)
  try {
    ignore(
      @spawn.spawn("launchctl", ["kickstart", "-k", launchd_service_target(uid)]),
    )
    logger.info("Restarted daemon via launchctl kickstart -k.")
  } catch {
    _ => {
      launchd_stop(config)
      @async.sleep(1_000)
      ignore(launchd_ensure_running(config))
    }
  }
}
