///|
/// An invocation of a tool on an MCP server.
struct ResponseOutputItemMcpCall {
  /// The unique ID of the tool call.
  id : String
  /// A JSON string of the arguments passed to the tool.
  arguments : String
  /// The name of the tool that was run.
  name : String
  /// The label of the MCP server running the tool.
  server_label : String
  /// Unique identifier for the MCP tool call approval request.
  approval_request_id : String?
  /// The error from the tool call, if any.
  error : String?
  /// The output from the tool call.
  output : String?
  /// The status of the tool call.
  status : ResponseOutputItemMcpCallStatus?
}

///|
/// The status of the MCP tool call.
enum ResponseOutputItemMcpCallStatus {
  InProgress
  Completed
  Incomplete
  Calling
  Failed
}

///|
pub impl ToJson for ResponseOutputItemMcpCallStatus with to_json(
  self : ResponseOutputItemMcpCallStatus,
) -> Json {
  match self {
    InProgress => "in_progress"
    Completed => "completed"
    Incomplete => "incomplete"
    Calling => "calling"
    Failed => "failed"
  }
}

///|
pub impl @json.FromJson for ResponseOutputItemMcpCallStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItemMcpCallStatus raise @json.JsonDecodeError {
  guard json is String(status_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseOutputItemMcpCallStatus: expected string"),
    )
  }
  match status_str {
    "in_progress" => InProgress
    "completed" => Completed
    "incomplete" => Incomplete
    "calling" => Calling
    "failed" => Failed
    _ =>
      raise @json.JsonDecodeError(
        (
          path,
          "ResponseOutputItemMcpCallStatus: invalid status '\{status_str}'",
        ),
      )
  }
}

///|
pub impl ToJson for ResponseOutputItemMcpCall with to_json(
  self : ResponseOutputItemMcpCall,
) -> Json {
  let obj : Map[String, Json] = {
    "type": "mcp_call",
    "id": self.id,
    "arguments": self.arguments,
    "name": self.name,
    "server_label": self.server_label,
  }
  if self.approval_request_id is Some(approval_request_id) {
    obj["approval_request_id"] = approval_request_id.to_json()
  }
  if self.error is Some(error) {
    obj["error"] = error.to_json()
  }
  if self.output is Some(output) {
    obj["output"] = output.to_json()
  }
  if self.status is Some(status) {
    obj["status"] = status.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseOutputItemMcpCall with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItemMcpCall raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let arguments : String = object.required("arguments", path~)
  let name : String = object.required("name", path~)
  let server_label : String = object.required("server_label", path~)
  let _ : String = object.required("type", path~)
  let approval_request_id : String? = object.optional(
    "approval_request_id",
    path~,
  )
  let error : String? = object.optional("error", path~)
  let output : String? = object.optional("output", path~)
  let status : ResponseOutputItemMcpCallStatus? = object.optional(
    "status",
    path~,
  )
  ResponseOutputItemMcpCall::{
    id,
    arguments,
    name,
    server_label,
    approval_request_id,
    error,
    output,
    status,
  }
}
