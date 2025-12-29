///|
/// Output content item for function call outputs.
pub enum ResponseFunctionCallOutputItem {
  InputText(ResponseInputText)
  InputImage(ResponseInputImage)
  InputFile(ResponseInputFile)
}

///|
pub impl ToJson for ResponseFunctionCallOutputItem with to_json(
  self : ResponseFunctionCallOutputItem,
) -> Json {
  match self {
    InputText(value) => value.to_json()
    InputImage(value) => value.to_json()
    InputFile(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseFunctionCallOutputItem with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionCallOutputItem raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  match type_ {
    "input_text" => InputText(@json.from_json(json, path~))
    "input_image" => InputImage(@json.from_json(json, path~))
    "input_file" => InputFile(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseFunctionCallOutputItem: invalid type '\{type_}'",
        ),
      )
  }
}

///|
pub type ResponseFunctionCallOutputItemList = Array[
  ResponseFunctionCallOutputItem,
]
