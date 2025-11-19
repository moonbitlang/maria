///|
test "Message to_json" {
  let messages : Array[Message] = [
    {
      timestamp: 1625079600,
      usage: None,
      message: User(
        @openai.ChatCompletionUserMessageParam::new(content=[
          @openai.ChatCompletionContentPartParam::new(text="Hello, world!"),
        ]),
      ),
    },
    {
      timestamp: 1625079600,
      usage: Some(
        @openai.CompletionUsage::new(
          prompt_tokens=10,
          total_tokens=20,
          completion_tokens=10,
        ),
      ),
      message: User(
        @openai.ChatCompletionUserMessageParam::new(content=[
          @openai.ChatCompletionContentPartParam::new(text="Hello, world!"),
        ]),
      ),
    },
  ]
  @json.inspect(messages, content=[
    {
      "timestamp": "1625079600",
      "message": { "role": "user", "content": "Hello, world!" },
    },
    {
      "timestamp": "1625079600",
      "message": { "role": "user", "content": "Hello, world!" },
      "usage": {
        "completion_tokens": 10,
        "prompt_tokens": 10,
        "total_tokens": 20,
      },
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
  let usage = match json.get("usage") {
    Some(Null) => None
    Some(usage) => Some(@json.from_json(usage, path=json_path.add_key("usage")))
    None => None
  }
  let message = match json.get("message") {
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
  Message::{ timestamp, usage, message }
}
