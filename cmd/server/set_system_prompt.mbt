///|
priv struct PostSystemPromptRequest(String?)

///|
impl @json.FromJson for PostSystemPromptRequest with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> PostSystemPromptRequest raise @json.JsonDecodeError {
  let system_prompt : String? = match json {
    Null => None
    _ => Some(@json.from_json(json, path=json_path))
  }
  PostSystemPromptRequest(system_prompt)
}

///|
async fn Server::set_system_prompt(
  self : Server,
  json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
  let req : PostSystemPromptRequest = @json.from_json(json) catch {
    @json.JsonDecodeError(_) as error =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid request body: \{error}",
          "data": { "error": error, "body": json },
        },
      })
  }
  self.maria.agent.set_system_prompt(req.0)
  let res : Json = {}
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(res.stringify())
}
