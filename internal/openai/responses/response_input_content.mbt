///|
/// Input content union for message inputs.
pub enum ResponseInputContent {
  InputText(ResponseInputText)
  InputImage(ResponseInputImage)
  InputFile(ResponseInputFile)
}

///|
pub impl ToJson for ResponseInputContent with to_json(
  self : ResponseInputContent,
) -> Json {
  match self {
    InputText(value) => value.to_json()
    InputImage(value) => value.to_json()
    InputFile(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseInputContent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputContent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  match type_ {
    "input_text" => InputText(@json.from_json(json, path~))
    "input_image" => InputImage(@json.from_json(json, path~))
    "input_file" => InputFile(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("type"), "ResponseInputContent: invalid type '\{type_}'"),
      )
  }
}

///|
/// List of input content items.
pub type ResponseInputMessageContentList = Array[ResponseInputContent]
