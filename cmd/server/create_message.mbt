///|
/// Request body accepted by `POST /v1/message`. Holds the OpenAI-style message
/// plus an optional one-off web search toggle.
struct CreateMessageRequest {
  message : @ai.Message
  web_search : Bool?
}

///|
pub fn CreateMessageRequest::new(
  message~ : @ai.Message,
  web_search? : Bool,
) -> CreateMessageRequest {
  CreateMessageRequest::{ message, web_search }
}

///|
pub impl ToJson for CreateMessageRequest with to_json(
  self : CreateMessageRequest,
) -> Json {
  let object : Map[String, Json] = {
    "message": self.message.to_openai().to_json(),
  }
  if self.web_search is Some(ws) {
    object["web_search"] = ws.to_json()
  }
  Json::object(object)
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
  { message: @ai.Message::from_openai(message), web_search }
}

///|
test "CreateMessageRequest::from_json" {
  let json : Json = {
    "message": { "role": "user", "content": "Hello, world!" },
    "web_search": true,
  }
  let req : CreateMessageRequest = @json.from_json(json)
  @json.inspect(req.message, content=["User", "Hello, world!"])
  @json.inspect(req.web_search, content=[true])
}

///|
struct CreateMessageResponse {
  id : @uuid.Uuid
  queued : Bool
}

///|
pub fn CreateMessageResponse::new(
  id~ : @uuid.Uuid,
  queued~ : Bool,
) -> CreateMessageResponse {
  CreateMessageResponse::{ id, queued }
}

///|
pub impl ToJson for CreateMessageResponse with to_json(
  self : CreateMessageResponse,
) -> Json {
  { "id": self.id, "queued": self.queued }
}

///|
pub impl @json.FromJson for CreateMessageResponse with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CreateMessageResponse raise @json.JsonDecodeError {
  guard json is { "id": id, "queued": queued, .. } else {
    raise @json.JsonDecodeError(
      (json_path, "Expected JSON object for CreateMessageResponse"),
    )
  }
  let id : @uuid.Uuid = @json.from_json(id)
  let queued : Bool = @json.from_json(queued)
  CreateMessageResponse::{ id, queued }
}

///|
/// Queues a user message for processing and reports whether it started
/// immediately. The first message in an empty queue begins execution right
/// away; subsequent ones are enqueued until the agent becomes idle again.
async fn Server::create_message(
  self : Server,
  body_json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
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
  let response : CreateMessageResponse = CreateMessageResponse::{ id, queued }
  w.send_json(code=200, response.to_json())
}
