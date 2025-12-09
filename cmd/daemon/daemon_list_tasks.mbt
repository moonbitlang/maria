///|
/// Lists all tasks tracked by the daemon.
///
/// Endpoint: GET /v1/tasks
///
/// Response:
///
/// - 200 OK: JSON `{ "tasks": Task[] }`
async fn Daemon::list_tasks(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  // Always reload stopped tasks from disk to ensure we have the latest state in
  // memory
  self.load_stopped()
  let tasks = self.by_id.values().collect()
  let response : Json = { "tasks": tasks }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}
