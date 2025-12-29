///|
/// Tool choice mode options.
pub enum ToolChoiceOptions {
  None_
  Auto
  Required
}

///|
pub impl ToJson for ToolChoiceOptions with to_json(self : ToolChoiceOptions) -> Json {
  match self {
    None_ => "none"
    Auto => "auto"
    Required => "required"
  }
}

///|
pub impl @json.FromJson for ToolChoiceOptions with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceOptions raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "ToolChoiceOptions: expected string"))
  }
  match value {
    "none" => None_
    "auto" => Auto
    "required" => Required
    _ =>
      raise @json.JsonDecodeError(
        (path, "ToolChoiceOptions: invalid value '\{value}'"),
      )
  }
}

///|
/// Allowed tools configuration.
pub struct ToolChoiceAllowed {
  mode : ToolChoiceAllowedMode
  tools : Array[Json]
}

///|
pub enum ToolChoiceAllowedMode {
  Auto
  Required
}

///|
pub impl ToJson for ToolChoiceAllowedMode with to_json(
  self : ToolChoiceAllowedMode,
) -> Json {
  match self {
    Auto => "auto"
    Required => "required"
  }
}

///|
pub impl @json.FromJson for ToolChoiceAllowedMode with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceAllowedMode raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "ToolChoiceAllowedMode: expected string"),
    )
  }
  match value {
    "auto" => Auto
    "required" => Required
    _ =>
      raise @json.JsonDecodeError(
        (path, "ToolChoiceAllowedMode: invalid value '\{value}'"),
      )
  }
}

///|
pub impl ToJson for ToolChoiceAllowed with to_json(self : ToolChoiceAllowed) -> Json {
  { "mode": self.mode, "tools": self.tools, "type": "allowed_tools" }
}

///|
pub impl @json.FromJson for ToolChoiceAllowed with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceAllowed raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let mode : ToolChoiceAllowedMode = object.required("mode", path~)
  let tools : Array[Json] = object.required("tools", path~)
  let _ : String = object.required("type", path~)
  ToolChoiceAllowed::{ mode, tools }
}

///|
/// Force a specific apply_patch tool call.
pub struct ToolChoiceApplyPatch {}

///|
pub impl ToJson for ToolChoiceApplyPatch with to_json(_ : ToolChoiceApplyPatch) -> Json {
  { "type": "apply_patch" }
}

///|
pub impl @json.FromJson for ToolChoiceApplyPatch with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceApplyPatch raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  ToolChoiceApplyPatch::{  }
}

///|
/// Force a specific custom tool call.
pub struct ToolChoiceCustom {
  name : String
}

///|
pub impl ToJson for ToolChoiceCustom with to_json(self : ToolChoiceCustom) -> Json {
  { "name": self.name, "type": "custom" }
}

///|
pub impl @json.FromJson for ToolChoiceCustom with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceCustom raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let name : String = object.required("name", path~)
  let _ : String = object.required("type", path~)
  ToolChoiceCustom::{ name, }
}

///|
/// Force a specific function call.
pub struct ToolChoiceFunction {
  name : String
}

///|
pub impl ToJson for ToolChoiceFunction with to_json(self : ToolChoiceFunction) -> Json {
  { "name": self.name, "type": "function" }
}

///|
pub impl @json.FromJson for ToolChoiceFunction with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceFunction raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let name : String = object.required("name", path~)
  let _ : String = object.required("type", path~)
  ToolChoiceFunction::{ name, }
}

///|
/// Force a specific MCP tool call.
pub struct ToolChoiceMcp {
  server_label : String
  name : String?
}

///|
pub impl ToJson for ToolChoiceMcp with to_json(self : ToolChoiceMcp) -> Json {
  let obj : Map[String, Json] = {
    "server_label": self.server_label,
    "type": "mcp",
  }
  if self.name is Some(name) {
    obj["name"] = name.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ToolChoiceMcp with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceMcp raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let server_label : String = object.required("server_label", path~)
  let _ : String = object.required("type", path~)
  let name : String? = object.optional("name", path~)
  ToolChoiceMcp::{ server_label, name }
}

///|
/// Force a shell tool call.
pub struct ToolChoiceShell {}

///|
pub impl ToJson for ToolChoiceShell with to_json(_ : ToolChoiceShell) -> Json {
  { "type": "shell" }
}

///|
pub impl @json.FromJson for ToolChoiceShell with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceShell raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  ToolChoiceShell::{  }
}

///|
/// Hosted tool types.
pub enum ToolChoiceTypesType {
  FileSearch
  WebSearchPreview
  ComputerUsePreview
  WebSearchPreview2025_03_11
  ImageGeneration
  CodeInterpreter
}

///|
pub impl ToJson for ToolChoiceTypesType with to_json(self : ToolChoiceTypesType) -> Json {
  match self {
    FileSearch => "file_search"
    WebSearchPreview => "web_search_preview"
    ComputerUsePreview => "computer_use_preview"
    WebSearchPreview2025_03_11 => "web_search_preview_2025_03_11"
    ImageGeneration => "image_generation"
    CodeInterpreter => "code_interpreter"
  }
}

///|
pub impl @json.FromJson for ToolChoiceTypesType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceTypesType raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "ToolChoiceTypesType: expected string"))
  }
  match value {
    "file_search" => FileSearch
    "web_search_preview" => WebSearchPreview
    "computer_use_preview" => ComputerUsePreview
    "web_search_preview_2025_03_11" => WebSearchPreview2025_03_11
    "image_generation" => ImageGeneration
    "code_interpreter" => CodeInterpreter
    _ =>
      raise @json.JsonDecodeError(
        (path, "ToolChoiceTypesType: invalid value '\{value}'"),
      )
  }
}

///|
/// Hosted tool selection.
pub struct ToolChoiceTypes {
  type_ : ToolChoiceTypesType
}

///|
pub impl ToJson for ToolChoiceTypes with to_json(self : ToolChoiceTypes) -> Json {
  { "type": self.type_ }
}

///|
pub impl @json.FromJson for ToolChoiceTypes with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolChoiceTypes raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : ToolChoiceTypesType = object.required("type", path~)
  ToolChoiceTypes::{ type_, }
}

///|
/// Tool choice union.
pub enum ResponseToolChoice {
  Mode(ToolChoiceOptions)
  Allowed(ToolChoiceAllowed)
  Hosted(ToolChoiceTypes)
  Function(ToolChoiceFunction)
  Mcp(ToolChoiceMcp)
  Custom(ToolChoiceCustom)
  ApplyPatch(ToolChoiceApplyPatch)
  Shell(ToolChoiceShell)
}

///|
pub impl ToJson for ResponseToolChoice with to_json(self : ResponseToolChoice) -> Json {
  match self {
    Mode(value) => value.to_json()
    Allowed(value) => value.to_json()
    Hosted(value) => value.to_json()
    Function(value) => value.to_json()
    Mcp(value) => value.to_json()
    Custom(value) => value.to_json()
    ApplyPatch(value) => value.to_json()
    Shell(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseToolChoice with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseToolChoice raise @json.JsonDecodeError {
  match json {
    String(_) => Mode(@json.from_json(json, path~))
    Object(_) => {
      let object = @jsonx.as_object(json, path~)
      let type_ : String = object.required("type", path~)
      match type_ {
        "allowed_tools" => Allowed(@json.from_json(json, path~))
        "function" => Function(@json.from_json(json, path~))
        "mcp" => Mcp(@json.from_json(json, path~))
        "custom" => Custom(@json.from_json(json, path~))
        "apply_patch" => ApplyPatch(@json.from_json(json, path~))
        "shell" => Shell(@json.from_json(json, path~))
        "file_search"
        | "web_search_preview"
        | "computer_use_preview"
        | "web_search_preview_2025_03_11"
        | "image_generation"
        | "code_interpreter" => Hosted(@json.from_json(json, path~))
        _ =>
          raise @json.JsonDecodeError(
            (
              path.add_key("type"),
              "ResponseToolChoice: invalid type '\{type_}'",
            ),
          )
      }
    }
    _ =>
      raise @json.JsonDecodeError((path, "ResponseToolChoice: invalid value"))
  }
}
