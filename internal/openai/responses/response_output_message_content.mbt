///|
pub enum ResponseOutputMessageContent {
  OutputText(ResponseOutputText)
  Refusal(ResponseOutputRefusal)
}

///|
pub impl ToJson for ResponseOutputMessageContent with to_json(
  self : ResponseOutputMessageContent,
) -> Json {
  match self {
    OutputText(content) => content.to_json()
    Refusal(content) => content.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseOutputMessageContent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputMessageContent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "output_text" => OutputText(@json.from_json(json, path~))
    "refusal" => Refusal(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseOutputMessageContent: invalid type '\{type_str}'",
        ),
      )
  }
}
