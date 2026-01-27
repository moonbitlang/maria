///|
/// Output of a custom tool call.
pub struct ResponseCustomToolCallOutput {
  call_id : String
  output : ResponseCustomToolCallOutputOutput
  id : String?
  status : String?
}

///|
pub enum ResponseCustomToolCallOutputOutput {
  Text(String)
  OutputContentList(
    Array[ResponseCustomToolCallOutputOutputOutputContentListItem]
  )
}

///|
pub enum ResponseCustomToolCallOutputOutputOutputContentListItem {
  InputText(ResponseInputText)
  InputImage(ResponseInputImage)
  InputFile(ResponseInputFile)
}

///|
pub impl ToJson for ResponseCustomToolCallOutputOutputOutputContentListItem with to_json(
  self : ResponseCustomToolCallOutputOutputOutputContentListItem,
) -> Json {
  match self {
    InputText(value) => value.to_json()
    InputImage(value) => value.to_json()
    InputFile(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseCustomToolCallOutputOutputOutputContentListItem with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCustomToolCallOutputOutputOutputContentListItem raise @json.JsonDecodeError {
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
          "ResponseCustomToolCallOutputOutputOutputContentListItem: invalid type '\{type_}'",
        ),
      )
  }
}

///|
pub impl ToJson for ResponseCustomToolCallOutputOutput with to_json(
  self : ResponseCustomToolCallOutputOutput,
) -> Json {
  match self {
    Text(value) => value.to_json()
    OutputContentList(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseCustomToolCallOutputOutput with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCustomToolCallOutputOutput raise @json.JsonDecodeError {
  match json {
    String(value) => Text(value)
    Array(_) => OutputContentList(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseCustomToolCallOutputOutput: invalid value"),
      )
  }
}

///|
pub impl ToJson for ResponseCustomToolCallOutput with to_json(
  self : ResponseCustomToolCallOutput,
) -> Json {
  let obj : Map[String, Json] = {
    "call_id": self.call_id,
    "output": self.output,
    "type": "custom_tool_call_output",
  }
  if self.id is Some(id) {
    obj["id"] = id.to_json()
  }
  if self.status is Some(status) {
    obj["status"] = status.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseCustomToolCallOutput with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCustomToolCallOutput raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let call_id : String = object.required("call_id", path~)
  let output : ResponseCustomToolCallOutputOutput = object.required(
    "output",
    path~,
  )
  let _ : String = object.required("type", path~)
  let id : String? = object.optional("id", path~)
  let status : String? = object.optional("status", path~)
  ResponseCustomToolCallOutput::{ call_id, output, id, status }
}
