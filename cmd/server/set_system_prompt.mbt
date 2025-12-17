///|
/// Payload accepted by `POST /v1/system-prompt`. The body can be either a
/// string or `null`, the latter clearing any custom prompt.
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
/// Updates Maria's system prompt in-place. Passing `null` clears the prompt so
/// subsequent conversations fall back to the built-in default text.
async fn Server::set_system_prompt(
  self : Server,
  json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
  let req : PostSystemPromptRequest = @json.from_json(json) catch {
    @json.JsonDecodeError(_) as error =>
      raise @httpx.JsonError::from_error(@status.BadRequest, error)
  }
  self.maria.agent.set_system_prompt(req.0)
  w.send_json(code=200, {})
}
