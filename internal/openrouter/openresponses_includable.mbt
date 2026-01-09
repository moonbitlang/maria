///|
enum OpenResponsesIncludable {
  FileSearchCallResults
  MessageInputImageImageUrl
  ComputerCallOutputOutputImageUrl
  ReasoningEncryptedContent
  CodeInterpreterCallOutputs
}

///|
pub impl ToJson for OpenResponsesIncludable with to_json(
  self : OpenResponsesIncludable,
) -> Json {
  match self {
    FileSearchCallResults => "file_search_call.results"
    MessageInputImageImageUrl => "message.input_image.image_url"
    ComputerCallOutputOutputImageUrl => "computer_call_output.output.image_url"
    ReasoningEncryptedContent => "reasoning.encrypted_content"
    CodeInterpreterCallOutputs => "code_interpreter_call.outputs"
  }
}

///|
pub impl @json.FromJson for OpenResponsesIncludable with from_json(
  json : Json,
  path : @json.JsonPath,
) -> OpenResponsesIncludable raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.OpenResponsesIncludable::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "file_search_call.results" => OpenResponsesIncludable::FileSearchCallResults
    "message.input_image.image_url" =>
      OpenResponsesIncludable::MessageInputImageImageUrl
    "computer_call_output.output.image_url" =>
      OpenResponsesIncludable::ComputerCallOutputOutputImageUrl
    "reasoning.encrypted_content" =>
      OpenResponsesIncludable::ReasoningEncryptedContent
    "code_interpreter_call.outputs" =>
      OpenResponsesIncludable::CodeInterpreterCallOutputs
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
