///|
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
async fn Server::set_enabled_tools(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let request : PostEnabledToolsRequest = {
    let data = r.body.read_all().binary()
    let text : String = @encoding/utf8.decode(data) catch {
      // TODO(upstream): impl Show for @encoding/utf8.Malformed
      @encoding/utf8.Malformed(bytes) =>
        raise json_error(400, "BadRequest", {
          "error": {
            "code": -1,
            "message": "Invalid UTF-8 in request body: \{bytes}",
          },
        })
    }
    let json = @json.parse(text) catch {
      error =>
        raise json_error(400, "BadRequest", {
          "error": {
            "code": -1,
            "message": "Invalid JSON in request body: \{error}",
          },
        })
    }
    @json.from_json(json) catch {
      @json.JsonDecodeError(_) as error =>
        raise json_error(400, "BadRequest", {
          "error": {
            "code": -1,
            "message": "Invalid request body: \{error}",
            "data": { "error": error, "body": json },
          },
        })
    }
  }
  let tools = Set::new()
  for tool_name in request.0 {
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
  let response : Json = {}
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}
