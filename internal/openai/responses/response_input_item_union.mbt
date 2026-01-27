///|
/// Union of input items accepted by response instructions and inputs.
pub enum ResponseInputItem {
  EasyMessage(EasyInputMessage)
  InputMessage(ResponseInputMessageItem)
  OutputMessage(ResponseOutputMessage)
  FileSearchCall(ResponseFileSearchToolCall)
  ComputerCall(ResponseComputerToolCall)
  ComputerCallOutput(ResponseInputItemComputerCallOutput)
  WebSearchCall(ResponseFunctionWebSearch)
  FunctionCall(ResponseFunctionToolCall)
  FunctionCallOutput(ResponseInputItemFunctionCallOutput)
  Reasoning(ResponseReasoningItem)
  Compaction(ResponseCompactionItem)
  ImageGenerationCall(ResponseOutputItemImageGenerationCall)
  CodeInterpreterCall(ResponseCodeInterpreterToolCall)
  LocalShellCall(ResponseInputItemLocalShellCall)
  LocalShellCallOutput(ResponseInputItemLocalShellCallOutput)
  ShellCall(ResponseInputItemShellCall)
  ShellCallOutput(ResponseInputItemShellCallOutput)
  ApplyPatchCall(ResponseInputItemApplyPatchCall)
  ApplyPatchCallOutput(ResponseInputItemApplyPatchCallOutput)
  McpListTools(ResponseOutputItemMcpListTools)
  McpApprovalRequest(ResponseOutputItemMcpApprovalRequest)
  McpApprovalResponse(ResponseInputItemMcpApprovalResponse)
  McpCall(ResponseOutputItemMcpCall)
  CustomToolCallOutput(ResponseCustomToolCallOutput)
  CustomToolCall(ResponseCustomToolCall)
  ItemReference(ResponseInputItemItemReference)
}

///|
pub impl ToJson for ResponseInputItem with to_json(self : ResponseInputItem) -> Json {
  match self {
    EasyMessage(value) => value.to_json()
    InputMessage(value) => value.to_json()
    OutputMessage(value) => value.to_json()
    FileSearchCall(value) => value.to_json()
    ComputerCall(value) => value.to_json()
    ComputerCallOutput(value) => value.to_json()
    WebSearchCall(value) => value.to_json()
    FunctionCall(value) => value.to_json()
    FunctionCallOutput(value) => value.to_json()
    Reasoning(value) => value.to_json()
    Compaction(value) => value.to_json()
    ImageGenerationCall(value) => value.to_json()
    CodeInterpreterCall(value) => value.to_json()
    LocalShellCall(value) => value.to_json()
    LocalShellCallOutput(value) => value.to_json()
    ShellCall(value) => value.to_json()
    ShellCallOutput(value) => value.to_json()
    ApplyPatchCall(value) => value.to_json()
    ApplyPatchCallOutput(value) => value.to_json()
    McpListTools(value) => value.to_json()
    McpApprovalRequest(value) => value.to_json()
    McpApprovalResponse(value) => value.to_json()
    McpCall(value) => value.to_json()
    CustomToolCallOutput(value) => value.to_json()
    CustomToolCall(value) => value.to_json()
    ItemReference(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseInputItem with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputItem raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  match type_ {
    "message" => {
      let role_value : String? = object.optional("role", path~)
      let has_id = object.get("id") is Some(_)
      match role_value {
        Some("assistant") => OutputMessage(@json.from_json(json, path~))
        _ =>
          if has_id {
            InputMessage(@json.from_json(json, path~))
          } else {
            EasyMessage(@json.from_json(json, path~))
          }
      }
    }
    "file_search_call" => FileSearchCall(@json.from_json(json, path~))
    "computer_call" => ComputerCall(@json.from_json(json, path~))
    "computer_call_output" => ComputerCallOutput(@json.from_json(json, path~))
    "web_search_call" => WebSearchCall(@json.from_json(json, path~))
    "function_call" => FunctionCall(@json.from_json(json, path~))
    "function_call_output" => FunctionCallOutput(@json.from_json(json, path~))
    "reasoning" => Reasoning(@json.from_json(json, path~))
    "compaction" => Compaction(@json.from_json(json, path~))
    "image_generation_call" => ImageGenerationCall(@json.from_json(json, path~))
    "code_interpreter_call" => CodeInterpreterCall(@json.from_json(json, path~))
    "local_shell_call" => LocalShellCall(@json.from_json(json, path~))
    "local_shell_call_output" =>
      LocalShellCallOutput(@json.from_json(json, path~))
    "shell_call" => ShellCall(@json.from_json(json, path~))
    "shell_call_output" => ShellCallOutput(@json.from_json(json, path~))
    "apply_patch_call" => ApplyPatchCall(@json.from_json(json, path~))
    "apply_patch_call_output" =>
      ApplyPatchCallOutput(@json.from_json(json, path~))
    "mcp_list_tools" => McpListTools(@json.from_json(json, path~))
    "mcp_approval_request" => McpApprovalRequest(@json.from_json(json, path~))
    "mcp_approval_response" => McpApprovalResponse(@json.from_json(json, path~))
    "mcp_call" => McpCall(@json.from_json(json, path~))
    "custom_tool_call_output" =>
      CustomToolCallOutput(@json.from_json(json, path~))
    "custom_tool_call" => CustomToolCall(@json.from_json(json, path~))
    "item_reference" => ItemReference(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("type"), "ResponseInputItem: invalid type '\{type_}'"),
      )
  }
}
