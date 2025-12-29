///|
/// A request for human approval of a tool invocation.
struct ResponseOutputItemMcpApprovalRequest {
  /// The unique ID of the approval request.
  id : String
  /// A JSON string of arguments for the tool.
  arguments : String
  /// The name of the tool to run.
  name : String
  /// The label of the MCP server making the request.
  server_label : String
  /// The type of the item. Always `mcp_approval_request`.
  type_ : String
}

///|
pub impl ToJson for ResponseOutputItemMcpApprovalRequest with to_json(
  self : ResponseOutputItemMcpApprovalRequest,
) -> Json {
  {
    "type": self.type_,
    "id": self.id,
    "arguments": self.arguments,
    "name": self.name,
    "server_label": self.server_label,
  }
}

///|
pub impl @json.FromJson for ResponseOutputItemMcpApprovalRequest with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItemMcpApprovalRequest raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let arguments : String = object.required("arguments", path~)
  let name : String = object.required("name", path~)
  let server_label : String = object.required("server_label", path~)
  let type_ : String = object.required("type", path~)
  ResponseOutputItemMcpApprovalRequest::{
    id,
    arguments,
    name,
    server_label,
    type_,
  }
}
