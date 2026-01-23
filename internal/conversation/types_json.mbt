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
  json_inspect(messages, content=[
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
  let object = @jsonx.as_object(json, path=json_path)
  let timestamp : @clock.Timestamp = object.required(
    "timestamp",
    path=json_path,
  )
  let usage : @openai.CompletionUsage? = object.optional(
    "usage",
    path=json_path,
  )
  let usage = usage.map(@ai.Usage::from_openai)
  let message : @openai.ChatCompletionMessageParam = match
    object.get("message") {
    Some(message_json) =>
      @json.from_json(message_json, path=json_path.add_key("message"))
    None => {
      let content : String = object.required("content", path=json_path)
      let content = @json.parse(content) catch {
        error =>
          raise @json.JsonDecodeError(
            (json_path.add_key("content"), "Invalid JSON content: \{error}"),
          )
      }
      @json.from_json(content, path=json_path.add_key("content"))
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
