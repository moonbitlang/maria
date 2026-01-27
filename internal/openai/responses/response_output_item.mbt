///|
pub enum ResponseOutputItem {
  Message(ResponseOutputMessage)
  FileSearchCall(ResponseFileSearchToolCall)
  FunctionCall(ResponseFunctionToolCall)
  WebSearchCall(ResponseFunctionWebSearch)
  ComputerCall(ResponseComputerToolCall)
  Reasoning(ResponseReasoningItem)
  Compaction(ResponseCompactionItem)
  ImageGenerationCall(ResponseOutputItemImageGenerationCall)
  CodeInterpreterCall(ResponseCodeInterpreterToolCall)
  LocalShellCall(ResponseOutputItemLocalShellCall)
  ShellCall(ResponseFunctionShellToolCall)
  ShellCallOutput(ResponseFunctionShellToolCallOutput)
  ApplyPatchCall(ResponseApplyPatchToolCall)
  ApplyPatchCallOutput(ResponseApplyPatchToolCallOutput)
  McpCall(ResponseOutputItemMcpCall)
  McpListTools(ResponseOutputItemMcpListTools)
  McpApprovalRequest(ResponseOutputItemMcpApprovalRequest)
  CustomToolCall(ResponseCustomToolCall)
}

///|
pub impl ToJson for ResponseOutputItem with to_json(self : ResponseOutputItem) -> Json {
  match self {
    Message(item) => item.to_json()
    FileSearchCall(item) => item.to_json()
    FunctionCall(item) => item.to_json()
    WebSearchCall(item) => item.to_json()
    ComputerCall(item) => item.to_json()
    Reasoning(item) => item.to_json()
    Compaction(item) => item.to_json()
    ImageGenerationCall(item) => item.to_json()
    CodeInterpreterCall(item) => item.to_json()
    LocalShellCall(item) => item.to_json()
    ShellCall(item) => item.to_json()
    ShellCallOutput(item) => item.to_json()
    ApplyPatchCall(item) => item.to_json()
    ApplyPatchCallOutput(item) => item.to_json()
    McpCall(item) => item.to_json()
    McpListTools(item) => item.to_json()
    McpApprovalRequest(item) => item.to_json()
    CustomToolCall(item) => item.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseOutputItem with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItem raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "message" => Message(@json.from_json(json, path~))
    "file_search_call" => FileSearchCall(@json.from_json(json, path~))
    "function_call" => FunctionCall(@json.from_json(json, path~))
    "web_search_call" => WebSearchCall(@json.from_json(json, path~))
    "computer_call" => ComputerCall(@json.from_json(json, path~))
    "reasoning" => Reasoning(@json.from_json(json, path~))
    "compaction" => Compaction(@json.from_json(json, path~))
    "image_generation_call" => ImageGenerationCall(@json.from_json(json, path~))
    "code_interpreter_call" => CodeInterpreterCall(@json.from_json(json, path~))
    "local_shell_call" => LocalShellCall(@json.from_json(json, path~))
    "shell_call" => ShellCall(@json.from_json(json, path~))
    "shell_call_output" => ShellCallOutput(@json.from_json(json, path~))
    "apply_patch_call" => ApplyPatchCall(@json.from_json(json, path~))
    "apply_patch_call_output" =>
      ApplyPatchCallOutput(@json.from_json(json, path~))
    "mcp_call" => McpCall(@json.from_json(json, path~))
    "mcp_list_tools" => McpListTools(@json.from_json(json, path~))
    "mcp_approval_request" => McpApprovalRequest(@json.from_json(json, path~))
    "custom_tool_call" => CustomToolCall(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("type"), "ResponseOutputItem: invalid type '\{type_str}'"),
      )
  }
}
