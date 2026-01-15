///|
/// Runs the daemon event loop: starts the task manager, serves HTTP requests
/// (behind the shared CORS middleware), and blocks until cancelled.
///
/// Routes:
///
/// - GET  /              → serve UI `index.html`
/// - GET  /v1/events     → `get_events`
/// - GET  /v1/models     → `list_models`
/// - POST /v1/task/register → `register_task`
/// - GET  /v1/tasks      → `list_tasks`
/// - POST /v1/task       → `create_task`
/// - GET  /v1/task/{id}  → `get_task`
/// - ANY  /v1/task/{id}/... → `forward_to_task`
/// - GET  /v1/auth/status → `get_auth_status`
/// - POST /v1/auth/codex/start → `start_codex_auth` (callback on port 1455)
/// - POST /v1/auth/codex/logout → `logout_codex`
/// - POST /v1/auth/copilot/start → `start_copilot_auth`
/// - POST /v1/auth/copilot/logout → `logout_copilot`
/// - POST /v1/shutdown   → graceful shutdown response then stop server
/// - POST /v1/moonbit/publish → `publish_moonbit_module`
/// - GET  /{file}        → `serve_static_file`
pub async fn Daemon::serve(self : Daemon) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => self.process.start())
    self.httpx.serve(
      @httpx.cors((r, w) => {
        let paths = r.path.split("/").collect()
        println("[INFO] (Daemon) Received request: \{r.method_} \{r.path}")
        println("[INFO] (Daemon) Handling request paths: \{paths}")
        try {
          match (r.method_, paths) {
            (Options, _) => w.write_header(204)
            // GET /
            (Get, ["", ""]) => {
              let index_html = html_read_file(
                @pathx.join(self.serve, "index.html"),
              )
              w.header().set("Content-Type", "text/html")
              w.write_header(200)
              w.write(index_html)
            }
            (Get, ["", "v1", "events"]) => self.get_events(w)
            (Get, ["", "v1", "models"]) => self.list_models(w)
            (Post, ["", "v1", "task", "register"]) => self.register_task(r, w)
            (Get, ["", "v1", "tasks"]) => self.list_tasks(w)
            (Post, ["", "v1", "task"]) => self.create_task(group~, r, w)
            (Get, ["", "v1", "task", id]) => self.get_task(id, w)
            (Get, ["", "v1", "task", id, "events"]) =>
              self.get_task_events(id~, w)
            (method_, ["", "v1", "task", id, .. paths]) =>
              self.forward_to_task(method_~, group~, id~, paths~, r, w)
            // Auth endpoints
            (Get, ["", "v1", "auth", "status"]) => self.get_auth_status(w)
            (Post, ["", "v1", "auth", "codex", "start"]) =>
              self.start_codex_auth(group~, r, w)
            (Post, ["", "v1", "auth", "codex", "logout"]) => self.logout_codex(w)
            (Post, ["", "v1", "auth", "copilot", "start"]) =>
              self.start_copilot_auth(group~, r, w)
            (Post, ["", "v1", "auth", "copilot", "logout"]) =>
              self.logout_copilot(w)
            (Post, ["", "v1", "shutdown"]) => {
              w.header().set("Content-Type", "application/json")
              w.write_header(200)
              let response : Json = {}
              w.write(response.stringify())
              w.flush()
              // We need to close the writer before shutting down to ensure the
              w.close()
              group.return_immediately(())
            }
            (Post, ["", "v1", "moonbit", "publish"]) =>
              publish_moonbit_module(r, w)
            (Get, ["", .. file]) =>
              serve_static_file(w, serve=self.serve, path=file.join("/"))
            _ =>
              raise json_error(404, "NotFound", {
                "error": {
                  "code": -1,
                  "message": "Unknown endpoint: \{r.path}",
                  "metadata": {
                    "method": r.method_.to_string(),
                    "path": r.path,
                  },
                },
              })
          }
        } catch {
          HttpError(code~, reason~, body~) => {
            w.header().set("Content-Type", "application/json")
            w.write_header(code, reason~)
            w.write(body)
          }
          error => raise error
        }
      }),
    )
  })
}
