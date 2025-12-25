///|
/// Tool function metadata returned from the API.
pub struct ChatCompletionMessageToolCallFunction {
  arguments : String?
  name : String
} derive(Show)

///|
impl ToJson for ChatCompletionMessageToolCallFunction with to_json(
  self : ChatCompletionMessageToolCallFunction,
) -> Json {
  { "name": self.name, "arguments": self.arguments.unwrap_or("") }
}

///|
impl @json.FromJson for ChatCompletionMessageToolCallFunction with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessageToolCallFunction {
  guard json is { "name": String(name), "arguments"? : arguments, .. } else {
    raise @json.JsonDecodeError(
      (json_path, "Expected an object with 'name' field"),
    )
  }
  let arguments = match arguments {
    Some(String(arguments)) => Some(arguments)
    Some(Null) => None
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'arguments' to be a string"),
      )
    None => None
  }
  ChatCompletionMessageToolCallFunction::{ arguments, name }
}
