///|
/// Tool call emitted from an assistant message.
#alias(ChatCompletionMessageToolCallParam)
pub struct ChatCompletionMessageToolCall {
  id : String
  function : ChatCompletionMessageToolCallFunction
} derive(Debug)

///|
pub impl ToJson for ChatCompletionMessageToolCall with fn to_json(
  self : ChatCompletionMessageToolCall,
) -> Json {
  { "id": self.id, "function": self.function, "type": "function" }
}

///|
pub impl @json.FromJson for ChatCompletionMessageToolCall with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessageToolCall {
  guard json is { "id": String(id), "function": function, .. } else {
    raise @json.JsonDecodeError(
      (
        json_path, "Expected an object with 'id' and 'function' fields, the `id` must be a string",
      ),
    )
  }
  let function : ChatCompletionMessageToolCallFunction = @json.from_json(
    function,
    path=json_path.add_key("function"),
  )
  ChatCompletionMessageToolCall::{ id, function, }
}

///|
pub extend ChatCompletionMessageToolCall with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend ChatCompletionMessageToolCall with ToJson::{to_json}

///|
pub extend ChatCompletionMessageToolCall with @moonbitlang/core/json.FromJson::{
  from_json,
}
