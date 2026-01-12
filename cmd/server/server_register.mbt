///|
pub struct RegisterRequest {
  id : String
  port : Int
  new_id : @uuid.Uuid
  cwd : String
  web_search : Bool
  model : String
} derive(ToJson, FromJson)

///|
pub(all) struct RegisterResponse {} derive(ToJson, FromJson)

///|
/// Notifies the daemon about the server's listening port via
/// `/v1/task/register`.
async fn RegisterInfo::register(
  register : RegisterInfo,
  port~ : Int,
  new_id~ : @uuid.Uuid,
  web_search~ : Bool,
  cwd~ : String,
  model~ : String,
) -> RegisterResponse {
  logger.info("Listening on port \{port}", data={ "server": register.id })
  logger.info("Visit http://localhost:\{port}/ to access the server.", data={
    "server": register.id,
  })
  let req : RegisterRequest = {
    id: register.id,
    port,
    new_id,
    cwd,
    web_search,
    model,
  }
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
