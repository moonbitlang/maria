///|
priv struct Message {
  message : @openai.ChatCompletionMessageParam
  web_search : Bool?
}

///|
impl @json.FromJson for Message with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Message raise @json.JsonDecodeError {
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
  let req : Message = @json.from_json(json)
  @json.inspect(req.message, content={
    "role": "user",
    "content": "Hello, world!",
  })
  @json.inspect(req.web_search, content=[true])
}

///|
priv struct QueuedMessage {
  id : String
  queued : Bool
} derive(ToJson)

///|
async fn Server::create_message(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let r = JsonRequestReader::new(r)
  let w = JsonResponseWriter::new(w)
  let req : Message = r.read()
  let id = {
    let idq = @aqueue.new(kind=Unbounded)
    self.message_queue.put((req, idq))
    idq.get()
  }
  w.write_header(200)
  w.write({ id: id.to_string(), queued: true })
}
