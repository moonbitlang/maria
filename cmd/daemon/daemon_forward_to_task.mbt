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
