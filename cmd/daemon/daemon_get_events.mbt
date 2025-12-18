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
///
/// Notes:
///
/// - Sets `X-Accel-Buffering: no` to disable proxy buffering for real-time streaming.
async fn Daemon::get_events(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  let w = @httpx.EventStreamWriter::new(w)
  w.write_header(200)
  let tasks : Array[Task] = []
  for task in self.by_cwd.values().collect() {
    task.sync_status() catch {
      error =>
        println(
          "[WARN] (Daemon) Failed to sync status from task \{task.id}: \{error}",
        )
    }
    tasks.push(task)
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
  })
}
