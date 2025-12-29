///|
/// A list of tools available on an MCP server.
struct ResponseOutputItemMcpListTools {
  /// The unique ID of the list.
  id : String
  /// The label of the MCP server.
  server_label : String
  /// The tools available on the server.
  tools : Array[ResponseOutputItemMcpListToolsTool]
  /// Error message if the server could not list tools.
  error : String?
}

///|
/// A tool available on an MCP server.
struct ResponseOutputItemMcpListToolsTool {
  /// The JSON schema describing the tool's input.
  input_schema : Json
  /// The name of the tool.
  name : String
  /// Additional annotations about the tool.
  annotations : Json?
  /// The description of the tool.
  description : String?
}

///|
pub impl ToJson for ResponseOutputItemMcpListToolsTool with to_json(
  self : ResponseOutputItemMcpListToolsTool,
) -> Json {
  let obj : Map[String, Json] = {
    "input_schema": self.input_schema,
    "name": self.name,
  }
  if self.annotations is Some(annotations) {
    obj["annotations"] = annotations
  }
  if self.description is Some(description) {
    obj["description"] = description.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseOutputItemMcpListToolsTool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItemMcpListToolsTool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let input_schema : Json = object.required("input_schema", path~)
  let name : String = object.required("name", path~)
  let annotations : Json? = object.optional("annotations", path~)
  let description : String? = object.optional("description", path~)
  ResponseOutputItemMcpListToolsTool::{
    input_schema,
    name,
    annotations,
    description,
  }
}

///|
pub impl ToJson for ResponseOutputItemMcpListTools with to_json(
  self : ResponseOutputItemMcpListTools,
) -> Json {
  let obj : Map[String, Json] = {
    "type": "mcp_list_tools",
    "id": self.id,
    "server_label": self.server_label,
    "tools": self.tools,
  }
  if self.error is Some(error) {
    obj["error"] = error.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseOutputItemMcpListTools with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItemMcpListTools raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let server_label : String = object.required("server_label", path~)
  let tools : Array[ResponseOutputItemMcpListToolsTool] = object.required(
    "tools",
    path~,
  )
  let _ : String = object.required("type", path~)
  let error : String? = object.optional("error", path~)
  ResponseOutputItemMcpListTools::{ id, server_label, tools, error }
}
