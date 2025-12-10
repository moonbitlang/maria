///|
pub struct RegisterRequest {
  id : String
  port : Int
} derive(ToJson, FromJson)

///|
pub(all) struct RegisterResponse {} derive(ToJson, FromJson)

///|
/// Notifies the daemon about the server's listening port via
/// `/v1/task/register`.
async fn RegisterInfo::register(
  register : RegisterInfo,
  port~ : Int,
) -> RegisterResponse {
  println("[INFO] (Server \{register.id}) Listening on port \{port}")
  println(
    "[INFO] (Server \{register.id}) Visit http://localhost:\{port}/ to access the server.",
  )
  let req : RegisterRequest = { id: register.id, port }
  let (r, b) = @httpx.post_json(
    "http://\{register.host}:\{register.port}/v1/task/register",
    req.to_json(),
  )
  guard r.code is (200..=299) else {
    raise json_error(500, "InternalServerError", {
      "error": {
        "code": r.code,
        "message": r.reason,
        "metadata": { "body": b.text() },
      },
    })
  }
  @json.from_json(b.json()) catch {
    error =>
      raise json_error(500, "InternalServerError", {
        "error": {
          "code": -1,
          "message": "Failed to parse registration response: \{error}",
          "metadata": { "body": b.text() },
        },
      })
  }
}
