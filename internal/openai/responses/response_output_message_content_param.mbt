///|
/// Response output message content from either text or refusal.
enum ResponseOutputMessageContentParam {
  OutputText(ResponseOutputMessageTextContentParam)
  Refusal(ResponseOutputMessageRefusalContentParam)
}

///|
pub impl ToJson for ResponseOutputMessageContentParam with to_json(
  self : ResponseOutputMessageContentParam,
) -> Json {
  match self {
    OutputText(param) => param.to_json()
    Refusal(param) => param.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseOutputMessageContentParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputMessageContentParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "output_text" => {
      let param = @json.from_json(json, path~)
      OutputText(param)
    }
    "refusal" => {
      let param = @json.from_json(json, path~)
      Refusal(param)
    }
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseOutputMessageContentParam: invalid type '\{type_str}'",
        ),
      )
  }
}
