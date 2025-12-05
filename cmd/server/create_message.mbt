///|
priv struct CreateMessageRequest {
  message : @openai.ChatCompletionMessageParam
  web_search : Bool?
}

///|
impl @json.FromJson for CreateMessageRequest with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CreateMessageRequest raise @json.JsonDecodeError {
  guard json is { "message": message, .. } else {
    raise @json.JsonDecodeError(
      (json_path.add_key("message"), "Missing 'message' field in request body"),
    )
  }
  let message : @openai.ChatCompletionMessageParam = @json.from_json(message)
  let web_search : Bool? = match json {
    { "web_search": ws, .. } => Some(@json.from_json(ws))
    _ => None
  }
  { message, web_search }
}

///|
test "CreateMessageRequest::from_json" {
  let json : Json = {
    "message": { "role": "user", "content": "Hello, world!" },
    "web_search": true,
  }
  let req : CreateMessageRequest = @json.from_json(json)
  @json.inspect(req.message, content={
    "role": "user",
    "content": "Hello, world!",
  })
  @json.inspect(req.web_search, content=[true])
}

///|
async fn Server::create_message(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let body_data = r.body.read_all().binary()
  let body_text : String = @encoding/utf8.decode(body_data) catch {
    // TODO(upstream): impl Show for @encoding/utf8.Malformed
    @encoding/utf8.Malformed(bytes) =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid UTF-8 in request body: \{bytes}",
        },
      })
  }
  let body_json = @json.parse(body_text) catch {
    error =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid JSON in request body: \{error}",
        },
      })
  }
  let request : CreateMessageRequest = @json.from_json(body_json) catch {
    @json.JsonDecodeError(_) as error =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid 'message' field: \{error}",
          "data": { "error": error, "body": body_json },
        },
      })
  }
  let (id, queued) = {
    let idq = @aqueue.new(kind=Unbounded)
    self.message_queue.put((request, idq))
    idq.get()
  }
  let response : Json = { "id": id, "queued": queued }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}
