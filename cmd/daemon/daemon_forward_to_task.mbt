///|
/// Proxies any task-scoped HTTP calls directly to the task server.
///
/// Endpoint: ANY /v1/task/{id}/...
///
/// Request:
///
/// - Path params: `id` (UUID), `...paths` (remaining segments forwarded under `/v1/{path}`).
/// - Method: forwarded as-is (GET/POST/etc.).
/// - Body: streamed to the task server.
///
/// Response:
///
/// - Mirrors the task server's status code, reason, headers, and body.
/// - If `Content-Type` is `text/event-stream`, sets `X-Accel-Buffering: no`.
///
/// Errors:
///
/// - 400 Bad Request: Invalid UUID.
/// - 404 Not Found: Unknown task `id`.
async fn Daemon::forward_to_task(
  self : Daemon,
  group~ : @async.TaskGroup[Unit],
  method_~ : @httpx.Method,
  id~ : StringView,
  paths~ : ArrayView[StringView],
  r : @httpx.RequestReader,
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
  let task : Running = match task {
    Running(task) => task
    Stopped(task) => {
      let cwd = task.cwd
      let task_list = self.by_cwd.get_or_init(cwd, () => TaskLock::new())
      task_list.spawn_mutex.acquire()
      defer task_list.spawn_mutex.release()
      if task_list.running is Some(_) {
        w.write_header(409, reason="Conflict")
        w.write(
          Json::object({
            "error": {
              "code": -1,
              "message": "A running task already exists for the specified 'cwd': \{cwd}",
              "metadata": { "cwd": cwd },
            },
          }),
        )
        return
      } else {
        let task = self.spawn_task(
          group~,
          name?=task.name,
          cwd=task.cwd,
          resume_id=task.id,
          broadcast=task.broadcast,
        )
        task_list.running = Some(task)
        task
      }
    }
  }
  let path = paths.join("/")
  let c = @http.Client::new("http://localhost:\{task.port}")
  c.request(method_.to_http(), "/v1/\{path}")
  c.write_reader(r.body)
  let r = c.end_request()
  if r.headers.get("content-type") is Some(content_type) {
    w.header().set("Content-Type", content_type)
    if content_type is "text/event-stream" {
      w.header().set("X-Accel-Buffering", "no")
    }
  }
  w.write_header(r.code, reason=r.reason)
  w.write_reader(c)
  w.flush()
}
