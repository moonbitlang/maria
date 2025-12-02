///|
async test "Message to_json" (t : @test.Test) {
  @mock.run(t, mock => {
    let messages : Array[Message] = [
      {
        id: mock.uuid.v4(),
        timestamp: 1625079600,
        usage: None,
        message: @ai.user_message(content="Hello, world!"),
        web_search: false,
      },
      {
        id: mock.uuid.v4(),
        timestamp: 1625079600,
        usage: Some(
          @ai.usage(input_tokens=10, total_tokens=20, output_tokens=10),
        ),
        message: @ai.user_message(content="Hello, world!"),
        web_search: false,
      },
    ]
    @json.inspect(messages, content=[
      {
        "timestamp": 1625079600,
        "message": { "role": "user", "content": "Hello, world!" },
      },
      {
        "timestamp": 1625079600,
        "usage": {
          "completion_tokens": 10,
          "prompt_tokens": 10,
          "total_tokens": 20,
        },
        "message": { "role": "user", "content": "Hello, world!" },
      },
    ])
  })
}

///|
test "Message::FromJson" {
  let json : Json = {
    "name": "history",
    "id": "6b1a3b06-5544-4fc1-84cd-9edbcc8db9f0",
    "messages": [
      {
        "timestamp": 1764756332368,
        "message": {
          "role": "user",
          "content": "Hello, please call me Mr. Rabbit.",
        },
      },
      {
        "timestamp": 1764756332368,
        "message": {
          "role": "assistant",
          "tool_calls": [],
          "content": "Hello, Mr. Rabbit! Nice to meet you. How can I help you today?",
        },
      },
    ],
    "created_at": 1764756328431,
    "updated_at": 1764756332368,
  }
  let conversation : Conversation = @json.from_json(json)
  @json.inspect(conversation, content={
    "id": "6b1a3b06-5544-4fc1-84cd-9edbcc8db9f0",
    "name": "history",
    "messages": [
      {
        "timestamp": 1764756332368,
        "message": {
          "role": "user",
          "content": "Hello, please call me Mr. Rabbit.",
        },
      },
      {
        "timestamp": 1764756332368,
        "message": {
          "role": "assistant",
          "tool_calls": [],
          "content": "Hello, Mr. Rabbit! Nice to meet you. How can I help you today?",
        },
      },
    ],
    "created_at": 1764756328431,
    "updated_at": 1764756332368,
  })
}

///|
impl @json.FromJson for Message with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Message raise @json.JsonDecodeError {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected object for Message"))
  }
  let id = match json.get("id") {
    Some(id) => @json.from_json(id, path=json_path.add_key("id"))
    None => @uuid.nil
  }
  let timestamp = match json.get("timestamp") {
    Some(Number(timestamp, repr=None)) => timestamp.to_int64()
    Some(Number(_, repr=Some(repr))) =>
      @strconv.parse_uint64(repr).reinterpret_as_int64() catch {
        error =>
          raise @json.JsonDecodeError(
            (json_path.add_key("timestamp"), "Invalid timestamp: \{error}"),
          )
      }
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path.add_key("timestamp"), "Invalid timestamp"),
      )
    None =>
      raise @json.JsonDecodeError(
        (json_path.add_key("timestamp"), "Missing field"),
      )
  }
  let usage : @openai.CompletionUsage? = match json.get("usage") {
    Some(Null) => None
    Some(usage) => Some(@json.from_json(usage, path=json_path.add_key("usage")))
    None => None
  }
  let usage = usage.map(@ai.Usage::from_openai)
  let message : @openai.ChatCompletionMessageParam = match json.get("message") {
    Some(message) => @json.from_json(message, path=json_path.add_key("message"))
    None => {
      let content : String = match json.get("content") {
        Some(content) =>
          @json.from_json(content, path=json_path.add_key("content"))
        None =>
          raise @json.JsonDecodeError(
            (json_path.add_key("content"), "Missing field"),
          )
      }
      let content = @json.parse(content) catch {
        error =>
          raise @json.JsonDecodeError(
            (json_path.add_key("content"), "Invalid JSON content: \{error}"),
          )
      }
      @json.from_json(content)
    }
  }
  let web_search = match json.get("web_search") {
    Some(True) => true
    Some(False) => false
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path.add_key("web_search"), "Invalid boolean value"),
      )
    None => false
  }
  Message::{
    id,
    timestamp,
    usage,
    message: @ai.Message::from_openai(message),
    web_search,
  }
}

///|
impl ToJson for Message with to_json(self : Message) -> Json {
  let object : Map[String, Json] = {}
  object["timestamp"] = Json::number(
    self.timestamp.to_double(),
    repr=self.timestamp.to_string(),
  )
  if self.usage is Some(usage) {
    object["usage"] = usage.to_openai().to_json()
  }
  object["message"] = self.message.to_openai().to_json()
  Json::object(object)
}
