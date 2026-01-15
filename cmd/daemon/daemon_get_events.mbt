///|
/// Streams daemon-wide status updates using Server-Sent Events (SSE).
///
/// Endpoint: GET /v1/events
///
/// Response:
///
/// - 200 OK: `text/event-stream` with events:
///   - `daemon.tasks.synchronized`: initial snapshot `{ "tasks": Task[] }`.
///   - `daemon.task.changed`: per-task updates `{ "task": Task }` when status changes.
///   - `auth.status.changed`: auth status changed `{ "provider": String, "authenticated": Bool }`.
///   - `auth.login.completed`: login completed `{ "provider": String }`.
///   - `auth.login.failed`: login failed `{ "provider": String, "message": String }`.
///
/// Notes:
///
/// - Sets `X-Accel-Buffering: no` to disable proxy buffering for real-time streaming.
async fn Daemon::get_events(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  let w = @httpx.EventStreamWriter::new(w)
  w.write_header(200)
  let tasks : Array[Task] = []
  for task in self.by_id.values().collect() {
    match task {
      Running(task) => {
        task.sync() catch {
          error =>
            println(
              "[WARN] (Daemon) Failed to sync status from task \{task.id}: \{error}",
            )
        }
        tasks.push(Running(task))
      }
      Stopped(task) => tasks.push(Stopped(task))
    }
  }
  w.write_event(
    event="daemon.tasks.synchronized",
    data=Json::object({ "tasks": tasks }),
  )
  self.events.listen_forever(e => match e {
    StatusChange(id) => {
      let data : Json = { "task": self.by_id[id] }
      w.write_event(event="daemon.task.changed", data~)
    }
    AuthStatusChanged(provider~, authenticated~) => {
      let data : Json = { "provider": provider, "authenticated": authenticated }
      w.write_event(event="auth.status.changed", data~)
    }
    AuthLoginCompleted(provider~) => {
      let data : Json = { "provider": provider }
      w.write_event(event="auth.login.completed", data~)
    }
    AuthLoginFailed(provider~, message~) => {
      let data : Json = { "provider": provider, "message": message }
      w.write_event(event="auth.login.failed", data~)
    }
  })
}
