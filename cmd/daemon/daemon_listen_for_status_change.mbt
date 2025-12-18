///|
/// Subscribes to a task's event stream and updates daemon-visible status.
///
/// Connects to the task's `GET /v1/events` SSE endpoint and reacts to
/// `maria` events:
///
/// - When the task emits a cancellation or stopping event → marks `Idle`.
/// - When the task emits a starting event → marks `Busy`.
///
/// Emits `StatusChange(task.id)` to the daemon's internal event queue after
/// each status transition.
async fn Daemon::listen_for_status_change(self : Daemon, task : Task) -> Unit {
  println(
    "[INFO] (Daemon) Listening for status changes from task \{task.id}...",
  )
  let (er, eb) = @http.get_stream("http://localhost:\{task.port}/v1/events")
  defer eb.close()
  guard er.code is (200..=299) else {
    raise json_error(500, "Internal Server Error", {
      "error": {
        "code": er.code,
        "message": "Failed to connect to task event stream: \{er.code} \{er.reason}",
        "metadata": {
          "code": er.code,
          "reason": er.reason,
          "body": eb.read_all().json(),
        },
      },
    })
  }
  println("[INFO] (Daemon) Connected to task \{task.id} event stream.")
  let eb = @httpx.EventStreamReader::new(eb)
  while eb.read_event() is Some(event) {
    guard event.event is Some("maria") else { continue }
    let json = @json.parse(event.data)
    let event : @event.Event = @json.from_json(json)
    if event.is_stopping() || event.is_cancellation() {
      println("[INFO] (Daemon) Task \{task.id} is now idle.")
      task.status = Idle
      self.events.put(StatusChange(task.id))
    } else if event.is_starting() {
      println("[INFO] (Daemon) Task \{task.id} is now busy.")
      task.status = Busy
      self.events.put(StatusChange(task.id))
    }
  }
}
