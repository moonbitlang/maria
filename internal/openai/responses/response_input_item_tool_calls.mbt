///|
/// The output of a computer tool call.
pub struct ResponseInputItemComputerCallOutput {
  call_id : String
  output : ResponseComputerToolCallOutputScreenshot
  id : String?
  acknowledged_safety_checks : Array[
    ResponseInputItemComputerCallOutputAcknowledgedSafetyCheck,
  ]?
  status : String?
}

///|
pub struct ResponseInputItemComputerCallOutputAcknowledgedSafetyCheck {
  id : String
  code : String?
  message : String?
}

///|
pub impl ToJson for ResponseInputItemComputerCallOutputAcknowledgedSafetyCheck with to_json(
  self : ResponseInputItemComputerCallOutputAcknowledgedSafetyCheck,
) -> Json {
  let obj : Map[String, Json] = { "id": self.id }
  if self.code is Some(code) {
    obj["code"] = code.to_json()
  }
  if self.message is Some(message) {
    obj["message"] = message.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemComputerCallOutputAcknowledgedSafetyCheck with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemComputerCallOutputAcknowledgedSafetyCheck raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let code : String? = object.optional("code", path~)
  let message : String? = object.optional("message", path~)
  ResponseInputItemComputerCallOutputAcknowledgedSafetyCheck::{
    id,
    code,
    message,
  }
}

///|
pub impl ToJson for ResponseInputItemComputerCallOutput with to_json(
  self : ResponseInputItemComputerCallOutput,
) -> Json {
  let obj : Map[String, Json] = {
    "call_id": self.call_id,
    "output": self.output,
    "type": "computer_call_output",
  }
  if self.id is Some(id) {
    obj["id"] = id.to_json()
  }
  if self.acknowledged_safety_checks is Some(acknowledged_safety_checks) {
    obj["acknowledged_safety_checks"] = acknowledged_safety_checks.to_json()
  }
  if self.status is Some(status) {
    obj["status"] = status.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemComputerCallOutput with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemComputerCallOutput raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let call_id : String = object.required("call_id", path~)
  let output : ResponseComputerToolCallOutputScreenshot = object.required(
    "output",
    path~,
  )
  let _ : String = object.required("type", path~)
  let id : String? = object.optional("id", path~)
  let acknowledged_safety_checks : Array[
    ResponseInputItemComputerCallOutputAcknowledgedSafetyCheck,
  ]? = object.optional("acknowledged_safety_checks", path~)
  let status : String? = object.optional("status", path~)
  ResponseInputItemComputerCallOutput::{
    call_id,
    output,
    id,
    acknowledged_safety_checks,
    status,
  }
}

///|
/// Output of a function tool call.
pub struct ResponseInputItemFunctionCallOutput {
  call_id : String
  output : ResponseInputItemFunctionCallOutputOutput
  id : String?
  status : String?
}

///|
pub enum ResponseInputItemFunctionCallOutputOutput {
  Text(String)
  OutputItems(ResponseFunctionCallOutputItemList)
}

///|
pub impl ToJson for ResponseInputItemFunctionCallOutputOutput with to_json(
  self : ResponseInputItemFunctionCallOutputOutput,
) -> Json {
  match self {
    Text(value) => value.to_json()
    OutputItems(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseInputItemFunctionCallOutputOutput with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemFunctionCallOutputOutput raise @json.JsonDecodeError {
  match json {
    String(value) => Text(value)
    Array(_) => OutputItems(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseInputItemFunctionCallOutputOutput: invalid value"),
      )
  }
}

///|
pub impl ToJson for ResponseInputItemFunctionCallOutput with to_json(
  self : ResponseInputItemFunctionCallOutput,
) -> Json {
  let obj : Map[String, Json] = {
    "call_id": self.call_id,
    "output": self.output,
    "type": "function_call_output",
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
pub impl @json.FromJson for ResponseInputItemFunctionCallOutput with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemFunctionCallOutput raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let call_id : String = object.required("call_id", path~)
  let output : ResponseInputItemFunctionCallOutputOutput = object.required(
    "output",
    path~,
  )
  let _ : String = object.required("type", path~)
  let id : String? = object.optional("id", path~)
  let status : String? = object.optional("status", path~)
  ResponseInputItemFunctionCallOutput::{ call_id, output, id, status }
}

///|
/// A tool call to run a command on the local shell.
pub struct ResponseInputItemLocalShellCall {
  id : String
  action : ResponseInputItemLocalShellCallAction
  call_id : String
  status : String
}

///|
pub struct ResponseInputItemLocalShellCallAction {
  command : Array[String]
  env : Map[String, String]
  timeout_ms : Int64?
  user : String?
  working_directory : String?
}

///|
pub impl ToJson for ResponseInputItemLocalShellCallAction with to_json(
  self : ResponseInputItemLocalShellCallAction,
) -> Json {
  let obj : Map[String, Json] = {
    "command": self.command,
    "env": self.env,
    "type": "exec",
  }
  if self.timeout_ms is Some(timeout_ms) {
    obj["timeout_ms"] = timeout_ms.to_json()
  }
  if self.user is Some(user) {
    obj["user"] = user.to_json()
  }
  if self.working_directory is Some(working_directory) {
    obj["working_directory"] = working_directory.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemLocalShellCallAction with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemLocalShellCallAction raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let command : Array[String] = object.required("command", path~)
  let env : Map[String, String] = object.required("env", path~)
  let _ : String = object.required("type", path~)
  let timeout_ms : Int64? = object.optional("timeout_ms", path~)
  let user : String? = object.optional("user", path~)
  let working_directory : String? = object.optional("working_directory", path~)
  ResponseInputItemLocalShellCallAction::{
    command,
    env,
    timeout_ms,
    user,
    working_directory,
  }
}

///|
pub impl ToJson for ResponseInputItemLocalShellCall with to_json(
  self : ResponseInputItemLocalShellCall,
) -> Json {
  {
    "id": self.id,
    "action": self.action,
    "call_id": self.call_id,
    "status": self.status,
    "type": "local_shell_call",
  }
}

///|
pub impl @json.FromJson for ResponseInputItemLocalShellCall with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemLocalShellCall raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let action : ResponseInputItemLocalShellCallAction = object.required(
    "action",
    path~,
  )
  let call_id : String = object.required("call_id", path~)
  let status : String = object.required("status", path~)
  let _ : String = object.required("type", path~)
  ResponseInputItemLocalShellCall::{ id, action, call_id, status }
}

///|
/// Output of a local shell tool call.
pub struct ResponseInputItemLocalShellCallOutput {
  id : String
  output : String
  status : String?
}

///|
pub impl ToJson for ResponseInputItemLocalShellCallOutput with to_json(
  self : ResponseInputItemLocalShellCallOutput,
) -> Json {
  let obj : Map[String, Json] = {
    "id": self.id,
    "output": self.output,
    "type": "local_shell_call_output",
  }
  if self.status is Some(status) {
    obj["status"] = status.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemLocalShellCallOutput with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemLocalShellCallOutput raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let output : String = object.required("output", path~)
  let _ : String = object.required("type", path~)
  let status : String? = object.optional("status", path~)
  ResponseInputItemLocalShellCallOutput::{ id, output, status }
}

///|
/// A shell call item.
pub struct ResponseInputItemShellCall {
  action : ResponseInputItemShellCallAction
  call_id : String
  id : String?
  status : String?
}

///|
pub struct ResponseInputItemShellCallAction {
  commands : Array[String]
  max_output_length : Int64?
  timeout_ms : Int64?
}

///|
pub impl ToJson for ResponseInputItemShellCallAction with to_json(
  self : ResponseInputItemShellCallAction,
) -> Json {
  let obj : Map[String, Json] = { "commands": self.commands }
  if self.max_output_length is Some(max_output_length) {
    obj["max_output_length"] = max_output_length.to_json()
  }
  if self.timeout_ms is Some(timeout_ms) {
    obj["timeout_ms"] = timeout_ms.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemShellCallAction with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemShellCallAction raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let commands : Array[String] = object.required("commands", path~)
  let max_output_length : Int64? = object.optional("max_output_length", path~)
  let timeout_ms : Int64? = object.optional("timeout_ms", path~)
  ResponseInputItemShellCallAction::{ commands, max_output_length, timeout_ms }
}

///|
pub impl ToJson for ResponseInputItemShellCall with to_json(
  self : ResponseInputItemShellCall,
) -> Json {
  let obj : Map[String, Json] = {
    "action": self.action,
    "call_id": self.call_id,
    "type": "shell_call",
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
pub impl @json.FromJson for ResponseInputItemShellCall with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemShellCall raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let action : ResponseInputItemShellCallAction = object.required(
    "action",
    path~,
  )
  let call_id : String = object.required("call_id", path~)
  let _ : String = object.required("type", path~)
  let id : String? = object.optional("id", path~)
  let status : String? = object.optional("status", path~)
  ResponseInputItemShellCall::{ action, call_id, id, status }
}

///|
/// Output items emitted by a shell tool call.
pub struct ResponseInputItemShellCallOutput {
  call_id : String
  output : Array[ResponseFunctionShellCallOutputContent]
  id : String?
  max_output_length : Int64?
}

///|
pub impl ToJson for ResponseInputItemShellCallOutput with to_json(
  self : ResponseInputItemShellCallOutput,
) -> Json {
  let obj : Map[String, Json] = {
    "call_id": self.call_id,
    "output": self.output,
    "type": "shell_call_output",
  }
  if self.id is Some(id) {
    obj["id"] = id.to_json()
  }
  if self.max_output_length is Some(max_output_length) {
    obj["max_output_length"] = max_output_length.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemShellCallOutput with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemShellCallOutput raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let call_id : String = object.required("call_id", path~)
  let output : Array[ResponseFunctionShellCallOutputContent] = object.required(
    "output",
    path~,
  )
  let _ : String = object.required("type", path~)
  let id : String? = object.optional("id", path~)
  let max_output_length : Int64? = object.optional("max_output_length", path~)
  ResponseInputItemShellCallOutput::{ call_id, output, id, max_output_length }
}

///|
/// Apply patch call input item.
pub struct ResponseInputItemApplyPatchCall {
  call_id : String
  operation : ResponseApplyPatchToolCallOperation
  status : String
  id : String?
}

///|
pub impl ToJson for ResponseInputItemApplyPatchCall with to_json(
  self : ResponseInputItemApplyPatchCall,
) -> Json {
  let obj : Map[String, Json] = {
    "call_id": self.call_id,
    "operation": self.operation,
    "status": self.status,
    "type": "apply_patch_call",
  }
  if self.id is Some(id) {
    obj["id"] = id.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemApplyPatchCall with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemApplyPatchCall raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let call_id : String = object.required("call_id", path~)
  let operation : ResponseApplyPatchToolCallOperation = object.required(
    "operation",
    path~,
  )
  let status : String = object.required("status", path~)
  let _ : String = object.required("type", path~)
  let id : String? = object.optional("id", path~)
  ResponseInputItemApplyPatchCall::{ call_id, operation, status, id }
}

///|
/// Apply patch call output item.
pub struct ResponseInputItemApplyPatchCallOutput {
  call_id : String
  status : String
  id : String?
  output : String?
}

///|
pub impl ToJson for ResponseInputItemApplyPatchCallOutput with to_json(
  self : ResponseInputItemApplyPatchCallOutput,
) -> Json {
  let obj : Map[String, Json] = {
    "call_id": self.call_id,
    "status": self.status,
    "type": "apply_patch_call_output",
  }
  if self.id is Some(id) {
    obj["id"] = id.to_json()
  }
  if self.output is Some(output) {
    obj["output"] = output.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemApplyPatchCallOutput with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemApplyPatchCallOutput raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let call_id : String = object.required("call_id", path~)
  let status : String = object.required("status", path~)
  let _ : String = object.required("type", path~)
  let id : String? = object.optional("id", path~)
  let output : String? = object.optional("output", path~)
  ResponseInputItemApplyPatchCallOutput::{ call_id, status, id, output }
}

///|
/// Response to an MCP approval request.
pub struct ResponseInputItemMcpApprovalResponse {
  approval_request_id : String
  approve : Bool
  id : String?
  reason : String?
}

///|
pub impl ToJson for ResponseInputItemMcpApprovalResponse with to_json(
  self : ResponseInputItemMcpApprovalResponse,
) -> Json {
  let obj : Map[String, Json] = {
    "approval_request_id": self.approval_request_id,
    "approve": self.approve.to_json(),
    "type": "mcp_approval_response",
  }
  if self.id is Some(id) {
    obj["id"] = id.to_json()
  }
  if self.reason is Some(reason) {
    obj["reason"] = reason.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemMcpApprovalResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemMcpApprovalResponse raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let approval_request_id : String = object.required(
    "approval_request_id",
    path~,
  )
  let approve : Bool = object.required("approve", path~)
  let _ : String = object.required("type", path~)
  let id : String? = object.optional("id", path~)
  let reason : String? = object.optional("reason", path~)
  ResponseInputItemMcpApprovalResponse::{
    approval_request_id,
    approve,
    id,
    reason,
  }
}

///|
/// An internal identifier for an item to reference.
pub struct ResponseInputItemItemReference {
  id : String
  type_ : String?
}

///|
pub impl ToJson for ResponseInputItemItemReference with to_json(
  self : ResponseInputItemItemReference,
) -> Json {
  let obj : Map[String, Json] = { "id": self.id }
  if self.type_ is Some(type_) {
    obj["type"] = type_.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputItemItemReference with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItemItemReference raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let type_ : String? = object.optional("type", path~)
  ResponseInputItemItemReference::{ id, type_ }
}
