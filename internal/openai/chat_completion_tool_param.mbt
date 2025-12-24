///|
/// Tool definitions accepted in chat completion requests.
pub enum ChatCompletionToolParam {
  Function(FunctionDefinition)
}

///|
pub impl ToJson for ChatCompletionToolParam with to_json(
  self : ChatCompletionToolParam,
) -> Json {
  match self {
    Function(function_definition) =>
      { "type": "function", "function": function_definition }
  }
}
