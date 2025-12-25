///|
/// Messages supplied to the chat completion endpoint.
pub(all) enum ChatCompletionMessageParam {
  System(ChatCompletionSystemMessageParam)
  User(ChatCompletionUserMessageParam)
  Assistant(ChatCompletionAssistantMessageParam)
  Tool(ChatCompletionToolMessageParam)
}

///|
pub impl ToJson for ChatCompletionMessageParam with to_json(
  self : ChatCompletionMessageParam,
) {
  fn content_parts_to_json(
    content_parts : Array[ChatCompletionContentPartParam],
    json : Map[String, Json],
  ) -> Unit {
    match content_parts {
      [] => ()
      [Text(text)] if text.cache_control is None =>
        json["content"] = text.text.to_json()
      [.. parts] => json["content"] = parts.to_json()
    }
  }

  match self {
    System(param) => {
      let json : Map[String, Json] = { "role": "system" }
      content_parts_to_json(param.content, json)
      if param.name is Some(name) {
        json["name"] = Json::string(name)
      }
      Json::object(json)
    }
    User(param) => {
      let json : Map[String, Json] = { "role": "user" }
      content_parts_to_json(param.content, json)
      if param.name is Some(name) {
        json["name"] = Json::string(name)
      }
      Json::object(json)
    }
    Assistant(param) => {
      let json : Map[String, Json] = {
        "role": "assistant",
        "tool_calls": param.tool_calls,
      }
      content_parts_to_json(param.content, json)
      if param.name is Some(name) {
        json["name"] = Json::string(name)
      }
      Json::object(json)
    }
    Tool(param) =>
      {
        "role": "tool",
        "content": param.content,
        "tool_call_id": param.tool_call_id,
      }
  }
}

///|
pub impl @json.FromJson for ChatCompletionMessageParam with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessageParam {
  guard json
    is {
      "role": "user"
      | "assistant"
      | "system"
      | "tool" as role,
      "content": content,
      "name"? : name,
      "tool_calls"? : tool_calls,
      "tool_call_id"? : tool_call_id,
      ..
    } else {
    raise @json.JsonDecodeError(
      (
        json_path, "Expected an object with a 'role' field which is one of 'user', 'assistant', 'system', or 'tool' and a 'content' field",
      ),
    )
  }
  match role {
    "user" => {
      let content : Array[ChatCompletionContentPartParam] = match content {
        String(text) => [text_content_part(text)]
        Array(_) as parts =>
          @json.from_json(parts, path=json_path.add_key("content"))
        _ =>
          raise @json.JsonDecodeError(
            (json_path, "Expected 'content' to be a string or array"),
          )
      }
      let name = match name {
        None | Some(Null) => None
        Some(String(name)) => Some(name)
        Some(_) =>
          raise @json.JsonDecodeError(
            (json_path, "Expected 'name' to be a string"),
          )
      }
      ChatCompletionMessageParam::User({ content, name })
    }
    "assistant" => {
      let content : Array[ChatCompletionContentPartParam] = match content {
        String(text) => [text_content_part(text)]
        Array(_) as parts =>
          @json.from_json(parts, path=json_path.add_key("content"))
        _ =>
          raise @json.JsonDecodeError(
            (json_path, "Expected 'content' to be a string or array"),
          )
      }
      let name = match name {
        None | Some(Null) => None
        Some(String(name)) => Some(name)
        Some(_) =>
          raise @json.JsonDecodeError(
            (json_path, "Expected 'name' to be a string"),
          )
      }
      guard tool_calls is Some(tool_calls) else {
        raise @json.JsonDecodeError((json_path, "Missing 'tool_calls' field"))
      }
      let tool_calls : Array[ChatCompletionMessageToolCallParam] = @json.from_json(
        tool_calls,
        path=json_path.add_key("tool_calls"),
      )
      ChatCompletionMessageParam::Assistant({ content, name, tool_calls })
    }
    "system" => {
      let content : Array[ChatCompletionContentPartParam] = match content {
        String(text) => [text_content_part(text)]
        Array(_) as parts =>
          @json.from_json(parts, path=json_path.add_key("content"))
        _ =>
          raise @json.JsonDecodeError(
            (json_path, "Expected 'content' to be a string or array"),
          )
      }
      let name = match name {
        None | Some(Null) => None
        Some(String(name)) => Some(name)
        Some(_) =>
          raise @json.JsonDecodeError(
            (json_path, "Expected 'name' to be a string"),
          )
      }
      ChatCompletionMessageParam::System({ content, name })
    }
    "tool" => {
      let content : Array[ChatCompletionContentPartParam] = match content {
        String(text) => [text_content_part(text)]
        Array(_) as parts =>
          @json.from_json(parts, path=json_path.add_key("content"))
        _ =>
          raise @json.JsonDecodeError(
            (json_path, "Expected 'content' to be a string or array"),
          )
      }
      guard tool_call_id is Some(String(tool_call_id)) else {
        raise @json.JsonDecodeError((json_path, "Missing 'tool_call_id' field"))
      }
      ChatCompletionMessageParam::Tool({ content, tool_call_id })
    }
    _ => abort("unreachable")
  }
}
