///|
/// Lists all tasks tracked by the daemon.
///
/// Endpoint: GET /v1/tasks
///
/// Response:
///
/// - 200 OK: JSON `{ "tasks": Task[] }`
async fn Daemon::list_tasks(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  let tasks = self.by_cwd.values().collect()
  let response : Json = { "tasks": tasks }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}
