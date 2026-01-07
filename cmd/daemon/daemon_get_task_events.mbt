///|
async fn Daemon::get_task_events(
  self : Daemon,
  id~ : StringView,
  w : @httpx.ResponseWriter,
) -> Unit {
  println("[INFO] (Daemon) Subscribing to events for task '\{id}'")
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
  let broadcast = match task {
    Running(task) => task.broadcast
    Stopped(task) => task.broadcast
  }
  w.header().set("X-Accel-Buffering", "no")
  let w = @httpx.EventStreamWriter::new(w)
  w.write_header(200)
  for i = 0; ; i = i + 1 {
    let event = broadcast.read(i)
    w.write(event)
  }
}
