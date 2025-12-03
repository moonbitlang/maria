///|
priv struct EnabledTools(Array[String])

///|
impl @json.FromJson for EnabledTools with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> EnabledTools raise @json.JsonDecodeError {
  let tools : Array[String] = @json.from_json(json, path=json_path)
  EnabledTools(tools)
}

///|
async fn Server::set_enabled_tools(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let r = JsonRequestReader::new(r)
  let w = JsonResponseWriter::new(w)
  let req : EnabledTools = r.read()
  let tools = Set::new()
  for tool_name in req.0 {
    if tools.contains(tool_name) {
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Duplicate tool name in request: \{tool_name}",
        },
      })
    }
    tools.add(tool_name)
  }
  self.maria.agent.set_enabled_tools(tools)
  w.write_header(@status.Ok)
  w.write_json({})
}
