///|
/// Lists available model names provided by the daemon's model registry.
///
/// Endpoint: GET /v1/models
///
/// Response:
/// - 200 OK: JSON `{ "models": [{ "name": String }] }`.
async fn Daemon::list_models(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
  let models : Array[Json] = []
  for model in self.models.models() {
    models.push({ "name": model.name })
  }
  let response : Json = { "models": models }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}
