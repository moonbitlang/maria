///|
/// Thin wrapper over the JSON array used by `POST /v1/enabled-tools`.
priv struct PostEnabledToolsRequest(Array[String])

///|
impl @json.FromJson for PostEnabledToolsRequest with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> PostEnabledToolsRequest raise @json.JsonDecodeError {
  let tools : Array[String] = @json.from_json(json, path=json_path)
  PostEnabledToolsRequest(tools)
}

///|
/// Replaces the enabled-tool set with the exact list provided by the client.
/// Duplicated tool names are rejected so the API can surface user mistakes.
async fn Server::set_enabled_tools(
  self : Server,
  json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
  let request : PostEnabledToolsRequest = @json.from_json(json) catch {
    @json.JsonDecodeError(_) as error =>
      raise @httpx.JsonError::from_error(@status.BadRequest, error)
  }
  let tools = Set::new()
  for tool_name in request.0 {
    if tools.contains(tool_name) {
      raise @httpx.JsonError::new(@status.BadRequest, "Duplicate tool name")
    }
    tools.add(tool_name)
  }
  self.maria.agent.set_enabled_tools(tools)
  w.send_json(code=200, {})
}
