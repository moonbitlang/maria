///|
/// Retrieves a task by its ID.
///
/// Endpoint: GET /v1/task/{id}
///
/// Request:
///
/// - Path param: `id` (UUID string)
///
/// Response:
///
/// - 200 OK: JSON `{ "task": Task }`
///
/// Errors:
/// - 400 Bad Request: `id` is not a valid UUID.
/// - 404 Not Found: No task exists with the given `id`.
async fn Daemon::get_task(
  self : Daemon,
  id : StringView,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard self.by_id.get(
      @uuid.parse(id) catch {
        _ =>
          raise json_error(400, "Bad Request", {
            "error": { "code": -1, "message": "Invalid UUID: \{id}" },
          })
      },
    )
    is Some(task) else {
    raise json_error(404, "Not Found", {
      "error": { "code": -1, "message": "Task not found: \{id}" },
    })
  }
  if task is Running(task) {
    task.sync()
  }
  let response : Json = { "task": task }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}
