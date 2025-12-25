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
    raise @httpx.JsonError::new(
      @status.InternalServerError,
      "Failed to register server with daemon",
      data={
        "code": r.code,
        "reason": r.reason,
        "body": b.text() catch {
          _ => b.binary()
        },
      },
    )
  }
  @json.from_json(b.json()) catch {
    error =>
      raise @httpx.JsonError::new(
        @status.InternalServerError,
        "Failed to parse registration response: \{error}",
        data={
          "error": error.to_json(),
          "body": b.text() catch {
            _ => b.binary()
          },
        },
      )
  }
}
