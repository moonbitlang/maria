///|
/// Synchronizes all remote status from the task's HTTP server.
///
/// Parameters:
///
/// * `task` : The task to synchronize data for.
///
/// Throws an error if the HTTP requests fail or if the response parsing
/// encounters issues.
async fn Task::sync(task : Task) -> Unit {
  task.sync_status()
  task.sync_queued_messages()
}

///|
/// Synchronizes the status information from a task's HTTP server and updates
/// the local task status accordingly.
///
/// Parameters:
///
/// * `task` : The task whose status should be synchronized from its HTTP
///   server.
///
/// Throws an error if the HTTP request fails or if the JSON response cannot be
/// parsed properly.
async fn Task::sync_status(task : Task) -> Unit {
  let (r, b) = @http.get("http://localhost:\{task.port}/v1/status") catch {
    error => {
      println(
        "[WARN] (Daemon) Failed to sync status from task \{task.id}: \{error}",
      )
      raise error
    }
  }
  guard r.code is (200..=299) else {
    println(
      "[WARN] (Daemon) Failed to sync status from task \{task.id}: \{r.code} \{r.reason}",
    )
    return
  }
  let b = b.json() catch {
    error => {
      println(
        "[WARN] (Daemon) Failed to parse status JSON from task \{task.id}: \{error}",
      )
      raise error
    }
  }
  guard b is { "status": String(status_str), .. } else {
    println("[WARN] (Daemon) Invalid status format from task \{task.id}")
    return
  }
  match status_str.to_lower() {
    "idle" => task.status = @server.Idle
    "generating" => task.status = @server.Busy
    _ =>
      println(
        "[WARN] (Daemon) Unknown status '\{status_str}' from task \{task.id}",
      )
  }
}

///|
/// Synchronizes queued messages from a task's HTTP server and updates the local
/// task's queued message list.
///
/// Parameters:
///
/// * `task` : The task whose queued messages should be synchronized from its
///   HTTP server.
///
/// Throws an error of type `json_error` if the HTTP request fails, if the
/// response status code is not in the 200-299 range, if the JSON response
/// cannot be parsed properly, or if the response format is invalid.
async fn Task::sync_queued_messages(task : Task) -> Unit {
  task.queued_messages.clear()
  let (r, b) = @http.get("http://localhost:\{task.port}/v1/queued-messages") catch {
    error =>
      raise json_error(500, "Internal Server Error", {
        "error": {
          "code": -1,
          "message": "Failed to get queued messages from task: \{error}",
          "metadata": error.to_json(),
        },
      })
  }
  guard r.code is (200..=299) else {
    raise json_error(500, "Internal Server Error", {
      "error": {
        "code": r.code,
        "message": "Failed to get queued messages from task: \{r.code} \{r.reason}",
        "metadata": { "code": r.code, "reason": r.reason, "body": b.json() },
      },
    })
  }
  let b = b.json() catch {
    error =>
      raise json_error(500, "Internal Server Error", {
        "error": {
          "code": -1,
          "message": "Failed to parse queued messages JSON from task: \{error}",
          "metadata": error.to_json(),
        },
      })
  }
  guard b is Array(queued_messages) else {
    raise json_error(500, "Internal Server Error", {
      "error": {
        "code": -1,
        "message": "Invalid queued messages format from task",
        "metadata": { "body": b },
      },
    })
  }
  for m in queued_messages {
    guard m is { "id": String(id), "message": message, .. } else { continue }
    task.queued_messages.push({ id, message })
  }
}
