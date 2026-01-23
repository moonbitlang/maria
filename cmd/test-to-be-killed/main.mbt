///|
let logger : @pino.Logger = @pino.logger(
  "TestToBeKilled",
  @pino.Transport::console(),
)

///|
/// A simple daemon that holds a lock file and sleep indefinitely.
async fn main {
  let home = @os.home()
  let server = @httpx.Server::new("0.0.0.0", 0)
  let file = @daemon.lock_daemon_file(home~) catch {
    error => {
      logger.error("Failed to lock daemon file: \{error}")
      @os.exit(1)
    }
  }
  guard file is Some(file) else {
    logger.info("Failed to acquire daemon lock. Exiting.")
    @os.exit(0)
  }
  defer file.close()
  let info : Json = { "pid": @spawn.getpid(), "port": server.port() }
  file.write(info.stringify())
  logger.info(
    "Daemon started with PID \{@spawn.getpid()} and port \{server.port()}.",
  )
  while true {
    @async.sleep(1_000)
  }
}
