///|
/// Registers a task process with the daemon.
///
/// Endpoint: POST /v1/task/register
///
/// Request:
///
/// - Body: JSON `RegisterRequest` containing the task `id` and listening `port`.
///
/// Response:
///
/// - 200 OK: JSON `RegisterResponse` confirming registration.
///
/// Errors:
///
/// - 400 Bad Request: Invalid UTF-8, invalid JSON, or cannot decode `RegisterRequest`.
async fn Daemon::register_task(
  self : Daemon,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let request_bytes = r.body.read_all().binary()
  let request_text = @encoding/utf8.decode(request_bytes) catch {
    @encoding/utf8.Malformed(bytes) =>
      raise json_error(
        400,
        "Bad Request",
        "Invalid UTF-8 in request body: \{bytes}",
      )
  }
  let request_json = @json.parse(request_text) catch {
    error =>
      raise json_error(
        400,
        "Bad Request",
        "Invalid JSON in request body: \{error}",
      )
  }
  let register : @server.RegisterRequest = @json.from_json(request_json) catch {
    error =>
      raise json_error(
        400,
        "Bad Request",
        "Failed to decode RegisterRequest: \{error}",
      )
  }
  println("[INFO] Registered task '\{register.id}' on port \{register.port}")
  self.rqs[register.id].put(register.port)
  w.write_header(200)
  let res : @server.RegisterResponse = @server.RegisterResponse::{  }
  w.write(res.to_json())
}
