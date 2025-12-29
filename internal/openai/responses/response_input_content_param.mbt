///|
enum ResponseInputContentParam {
  InputText(ResponseInputTextParam)
} derive(Show)

///|
pub impl ToJson for ResponseInputContentParam with to_json(
  self : ResponseInputContentParam,
) -> Json {
  match self {
    InputText(param) => param.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseInputContentParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputContentParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "text" => {
      let param = @json.from_json(json, path~)
      InputText(param)
    }
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseInputContentParam: invalid type '\{type_str}'",
        ),
      )
  }
}
