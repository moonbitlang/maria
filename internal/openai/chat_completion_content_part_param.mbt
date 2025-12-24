///|
/// Content parts supported in chat completion parameters.
pub enum ChatCompletionContentPartParam {
  Text(ChatCompletionContentPartTextParam)
}

///|
pub fn ChatCompletionContentPartParam::new(
  text~ : String,
  cache_control? : CacheControl,
) -> ChatCompletionContentPartParam {
  ChatCompletionContentPartParam::Text({ text, cache_control })
}

///|
pub impl ToJson for ChatCompletionContentPartParam with to_json(
  self : ChatCompletionContentPartParam,
) -> Json {
  match self {
    Text(param) => {
      let json : Map[String, Json] = { "type": "text", "text": param.text }
      if param.cache_control is Some(cache_control) {
        json["cache_control"] = cache_control.to_json()
      }
      Json::object(json)
    }
  }
}

///|
impl @json.FromJson for ChatCompletionContentPartParam with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionContentPartParam raise {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("type") is Some(String(type_)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'type' field"))
  }
  match type_ {
    "text" => {
      guard json.get("text") is Some(String(text)) else {
        raise @json.JsonDecodeError((json_path, "Missing 'text' field"))
      }
      let cache_control = match json.get("cache_control") {
        None | Some(Null) => None
        Some(cache_control) => {
          let cache_control : CacheControl = @json.from_json(
            cache_control,
            path=json_path.add_key("cache_control"),
          )
          Some(cache_control)
        }
      }
      ChatCompletionContentPartParam::Text(ChatCompletionContentPartTextParam::{
        text,
        cache_control,
      })
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Unknown content part type: \{type_}"),
      )
  }
}
