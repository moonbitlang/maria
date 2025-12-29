///|
/// Reference to a prompt template and its variables.
pub struct ResponsePrompt {
  id : String
  variables : Map[String, ResponsePromptVariable]?
  version : String?
}

///|
/// Variable values for prompt templates.
pub enum ResponsePromptVariable {
  Text(String)
  InputText(ResponseInputText)
  InputImage(ResponseInputImage)
  InputFile(ResponseInputFile)
}

///|
pub impl ToJson for ResponsePromptVariable with to_json(
  self : ResponsePromptVariable,
) -> Json {
  match self {
    Text(value) => value.to_json()
    InputText(value) => value.to_json()
    InputImage(value) => value.to_json()
    InputFile(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponsePromptVariable with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponsePromptVariable raise @json.JsonDecodeError {
  match json {
    String(value) => Text(value)
    Object(obj) => {
      let type_value = obj.get("type")
      match type_value {
        Some(String("input_text")) => InputText(@json.from_json(json, path~))
        Some(String("input_image")) => InputImage(@json.from_json(json, path~))
        Some(String("input_file")) => InputFile(@json.from_json(json, path~))
        _ =>
          raise @json.JsonDecodeError(
            (path, "ResponsePromptVariable: invalid value"),
          )
      }
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponsePromptVariable: invalid value"),
      )
  }
}

///|
pub impl ToJson for ResponsePrompt with to_json(self : ResponsePrompt) -> Json {
  let obj : Map[String, Json] = { "id": self.id }
  if self.variables is Some(variables) {
    obj["variables"] = variables.to_json()
  }
  if self.version is Some(version) {
    obj["version"] = version.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponsePrompt with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponsePrompt raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let variables : Map[String, ResponsePromptVariable]? = object.optional(
    "variables",
    path~,
  )
  let version : String? = object.optional("version", path~)
  ResponsePrompt::{ id, variables, version }
}
