///|
/// Update procedure:
///
/// 1. Get the owner of the lock file. If there is no owner, make self as the
///    owner, and continue normal execution.
/// 2. If there is an owner, open the file in read-only mode, parse the JSON
///    content, and check the `version` field.
///
///    It is possible that the opening, reading, or parsing fails because:
///
///    1. The owner is starting and is currently writing to the file.
///    2. The owner is stopping and removing the file.
///
///    In both cases, we can retry a few times with backoff before giving up.
///    However, it is possible that multiple daemons are performing the upgrade
///    procedure at the same time. In that case, the owner might change during
///    the retries. Therefore, we need to detect if the owner of the file has
///    changed during the retries. If it has changed, it means another daemon
///    has taken over. However, we cannot simply give up, because the new owner
///    might also be an older version. Therefore, we need to keep retrying until
///    we can successfully read and parse the file, and check the version.
///
/// 3. If the version equally new or newer, give up and exit. If the version is
///    older, post `/v1/shutdown` to the owner process, and block waiting for
///    the file lock to be released (with a timeout). It is possible that
///    there are multiple daemons waiting for the same lock, so it is possible
///    that after the lock is released, the new owner is still not us. In that
///    case, we give up and exit.
///
/// FIXME: Make this private. This function is currently marked as public
/// because it is used by `cmd/test-to-be-killed` for testing.
pub async fn lock_daemon_file(home~ : StringView) -> @fs.File? {
  let path = home |> @pathx.join(".moonagent") |> @pathx.join("daemon.json")
  let dir = @pathx.dirname(path)
  @fsx.make_directory(dir, recursive=true, exists_ok=true)
  let old = match acquire_lock(path) {
    Ok(file) =>
      // Successfully acquired lock
      return Some(file)
    Err(old) => old
  }
  // If the owner version is older, request shutdown
  if old.version >= @buildinfo.version {
    println(
      "[INFO] (Daemon) Another daemon version \{old.version} is already running. Exiting.",
    )
    return None
  }
  println(
    "[INFO] (Daemon) Detected older daemon version \{old.version}. Requesting shutdown...",
  )
  if !request_shutdown(old.pid, old.port) {
    println("[ERROR] (Daemon) Failed to send shutdown request to older daemon.")
    @spawn.kill(old.pid, @signal.sigkill) catch {
      error => {
        println(
          "[ERROR] (Daemon) Failed to kill older daemon (pid=\{old.pid}): \{error}",
        )
        return None
      }
    }
    println("[INFO] (Daemon) Forcefully terminated older daemon.")
  } else {
    println("[INFO] (Daemon) Shutdown request sent successfully.")
  }
  // Wait for the lock to be released
  @async.with_timeout(60_000, () => {
    for {
      match acquire_lock(path) {
        Ok(file) =>
          // Successfully acquired lock
          break Some(file)
        Err(new) =>
          if new.pid != old.pid {
            // Lock is now held by another process; exit
            return None
          } else {
            // Still locked by the same process; wait and retry
            @async.sleep(500)
            continue
          }
      }
    }
  }) catch {
    @async.TimeoutError => {
      println(
        "[ERROR] (Daemon) Timeout waiting for older daemon to release lock.",
      )
      return None
    }
    error => raise error
  }
}

///|
/// Makes request to /v1/shutdown endpoint of the daemon with given `pid` and
/// `port` to request shutdown. Returns `true` if the request was successful.
///
/// This function has a 10-second timeout, in case of a non-responsive daemon
/// or a old version daemon that does not support the shutdown endpoint.
async fn request_shutdown(pid : Int, port : Int) -> Bool {
  try {
    let (r, _) = @async.with_timeout(10_000, () => {
      @httpx.post_json("http://localhost:\{port}/v1/shutdown", Json::object({}))
    })
    return r.code is (200..=299)
  } catch {
    error =>
      if @async.is_being_cancelled() {
        raise error
      } else {
        println(
          "[ERROR] (Daemon) Failed to send shutdown request to daemon (pid=\{pid}): \{error}",
        )
        return false
      }
  }
}
