///|
test "Message to_json" {
  let messages : Array[Message] = [
    {
      timestamp: @clock.Timestamp::from_ms(1625079600),
      usage: None,
      message: @ai.user_message(content="Hello, world!"),
    },
    {
      timestamp: @clock.Timestamp::from_ms(1625079600),
      usage: Some(@ai.usage(input_tokens=10, total_tokens=20, output_tokens=10)),
      message: @ai.user_message(content="Hello, world!"),
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
}

///|
impl @json.FromJson for Message with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Message raise @json.JsonDecodeError {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected object for Message"))
  }
  let timestamp = match json.get("timestamp") {
    Some(timestamp) =>
      @json.from_json(timestamp, path=json_path.add_key("timestamp"))
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
  Message::{ timestamp, usage, message: @ai.Message::from_openai(message) }
}

///|
impl ToJson for Message with to_json(self : Message) -> Json {
  let object : Map[String, Json] = {}
  object["timestamp"] = self.timestamp.to_json()
  if self.usage is Some(usage) {
    object["usage"] = usage.to_openai().to_json()
  }
  object["message"] = self.message.to_openai().to_json()
  Json::object(object)
}
