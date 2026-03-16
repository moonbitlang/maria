///|
async fn detach_ensure_running(config : ServiceConfig) -> Int {
  let home = config.home
  let args : Array[String] = ["daemon"]
  args.push("--port")
  args.push(config.port.to_string())
  args.push("--serve")
  args.push(config.serve)
  let pid = @process.spawn_orphan(config.exec_path, args)
  @async.with_timeout(60_000, () => {
    for ;; {
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
            if json is { "port": Number(port_f, ..), .. } {
              break port_f.to_int()
            }
          } else {
            // Another daemon took over — read its port
            let text = info_file.read_all().text()
            let json = @json.parse(text)
            if json is { "port": Number(port_f, ..), .. } {
              break port_f.to_int()
            }
          }
        }
      } catch {
        error =>
          if @async.is_being_cancelled() {
            raise error
          } else {
            logger.error("Waiting for daemon to start: \{error}")
          }
      }
      @async.sleep(500)
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
async fn detach_stop(config : ServiceConfig) -> Unit {
  match read_daemon_info(config.home) {
    Running(port~, ..) =>
      try {
        let (r, _) = @async.with_timeout(10_000, () => {
          @httpx.post_json(
            "http://localhost:\{port}/v1/shutdown",
            Json::object({}),
          )
        })
        if r.code is (200..=299) {
          logger.info("Daemon shutdown request sent successfully.")
        } else {
          logger.warn("Daemon shutdown returned status \{r.code}.")
        }
      } catch {
        _ => logger.warn("Failed to send shutdown request to daemon.")
      }
    _ => logger.info("Daemon is not running.")
  }
}

///|
async fn detach_restart(config : ServiceConfig) -> Unit {
  detach_stop(config)
  @async.sleep(1_000)
  detach_ensure_running(config) |> ignore()
}
