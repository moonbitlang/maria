///|
/// Tests for ResponseOutputItem variants

///|
test "ResponseOutputItem::Message" {
  let json : Json = {
    "type": "message",
    "id": "msg_001",
    "role": "assistant",
    "content": [{ "type": "output_text", "text": "Hello!", "annotations": [] }],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is Message(msg) else { fail("Expected Message variant") }
  json_inspect(msg.id, content="msg_001")
  json_inspect(msg.status.to_json(), content="completed")
}

///|
test "ResponseOutputItem::FunctionCall" {
  let json : Json = {
    "type": "function_call",
    "call_id": "call_123",
    "name": "get_weather",
    "arguments": "{\"location\": \"San Francisco\"}",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is FunctionCall(call) else {
    fail("Expected FunctionCall variant")
  }
  json_inspect(call.name, content="get_weather")
  json_inspect(call.call_id, content="call_123")
  json_inspect(call.arguments, content="{\"location\": \"San Francisco\"}")
}

///|
test "ResponseOutputItem::FunctionCall_with_status" {
  let json : Json = {
    "type": "function_call",
    "call_id": "call_456",
    "name": "search_docs",
    "arguments": "{\"query\": \"test\"}",
    "id": "func_789",
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is FunctionCall(call) else {
    fail("Expected FunctionCall variant")
  }
  json_inspect(call.id is Some(_), content=true)
  guard call.status is Some(status) else { fail("Expected Some status") }
  json_inspect(status.to_json(), content="completed")
}

///|
test "ResponseOutputItem::FileSearchCall" {
  let json : Json = {
    "type": "file_search_call",
    "id": "fs_001",
    "queries": ["search query 1", "search query 2"],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is FileSearchCall(call) else {
    fail("Expected FileSearchCall variant")
  }
  // Verify round-trip serialization works
  let output_json = call.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="fs_001")
}

///|
test "ResponseOutputItem::FileSearchCall_with_results" {
  let json : Json = {
    "type": "file_search_call",
    "id": "fs_002",
    "queries": ["find docs"],
    "status": "completed",
    "results": [
      {
        "file_id": "file_123",
        "filename": "test.pdf",
        "score": 0.95,
        "text": "Relevant content here",
      },
    ],
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is FileSearchCall(call) else {
    fail("Expected FileSearchCall variant")
  }
  let output_json = call.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  guard obj.get("results") is Some(Array(results)) else {
    fail("Expected results array")
  }
  json_inspect(results.length(), content=1)
}

///|
test "ResponseOutputItem::WebSearchCall" {
  let json : Json = {
    "type": "web_search_call",
    "id": "ws_001",
    "action": { "type": "search", "query": "test query", "sources": [] },
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is WebSearchCall(call) else {
    fail("Expected WebSearchCall variant")
  }
  let output_json = call.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="ws_001")
}

///|
test "ResponseOutputItem::Reasoning" {
  let json : Json = {
    "type": "reasoning",
    "id": "reason_001",
    "summary": [{ "type": "summary_text", "text": "Thinking about this..." }],
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is Reasoning(reasoning) else { fail("Expected Reasoning variant") }
  let output_json = reasoning.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="reason_001")
}

///|
test "ResponseOutputItem::Reasoning_with_content" {
  let json : Json = {
    "type": "reasoning",
    "id": "reason_002",
    "summary": [{ "type": "summary_text", "text": "Summary" }],
    "content": [{ "type": "reasoning_text", "text": "Detailed reasoning..." }],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is Reasoning(reasoning) else { fail("Expected Reasoning variant") }
  let output_json = reasoning.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj.get("content") is Some(_), content=true)
}

///|
test "ResponseOutputItem::CodeInterpreterCall" {
  let json : Json = {
    "type": "code_interpreter_call",
    "id": "ci_001",
    "code": "print('hello')",
    "container_id": "container_123",
    "outputs": [{ "type": "logs", "logs": "hello\n" }],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is CodeInterpreterCall(call) else {
    fail("Expected CodeInterpreterCall variant")
  }
  let output_json = call.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="ci_001")
  json_inspect(obj["code"], content="print('hello')")
}

///|
test "ResponseOutputItem::ShellCall" {
  let json : Json = {
    "type": "shell_call",
    "id": "shell_001",
    "action": {
      "commands": ["ls -la"],
      "max_output_length": 4096,
      "timeout_ms": 30000,
    },
    "call_id": "call_shell_001",
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ShellCall(call) else { fail("Expected ShellCall variant") }
  let output_json = call.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="shell_001")
}

///|
test "ResponseOutputItem::ApplyPatchCall" {
  let json : Json = {
    "type": "apply_patch_call",
    "id": "patch_001",
    "call_id": "call_patch_001",
    "operation": {
      "type": "update_file",
      "path": "/tmp/file.txt",
      "diff": "--- a/file.txt\n+++ b/file.txt\n@@ -1 +1 @@\n-old\n+new",
    },
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ApplyPatchCall(call) else {
    fail("Expected ApplyPatchCall variant")
  }
  let output_json = call.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="patch_001")
}

///|
test "ResponseOutputItem::McpCall" {
  let json : Json = {
    "type": "mcp_call",
    "id": "mcp_001",
    "name": "mcp_tool",
    "server_label": "my_server",
    "arguments": "{}",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is McpCall(call) else { fail("Expected McpCall variant") }
  let output_json = call.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="mcp_001")
}

///|
test "ResponseOutputItem::McpListTools" {
  let json : Json = {
    "type": "mcp_list_tools",
    "id": "mcp_list_001",
    "server_label": "my_server",
    "tools": [],
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is McpListTools(list) else {
    fail("Expected McpListTools variant")
  }
  let output_json = list.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="mcp_list_001")
}

///|
test "ResponseOutputItem::ImageGenerationCall" {
  let json : Json = {
    "type": "image_generation_call",
    "id": "img_001",
    "result": "base64_image_data_here",
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ImageGenerationCall(call) else {
    fail("Expected ImageGenerationCall variant")
  }
  let output_json = call.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="img_001")
}

///|
test "ResponseOutputItem::Compaction" {
  let json : Json = {
    "type": "compaction",
    "id": "comp_001",
    "encrypted_content": "encrypted_data_here",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is Compaction(comp) else { fail("Expected Compaction variant") }
  let output_json = comp.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="comp_001")
}

///|
test "ResponseOutputItem::invalid_type" {
  let json : Json = { "type": "invalid_type" }
  let result = try {
    let _ : @responses.ResponseOutputItem = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

///|
test "ResponseOutputItem::ComputerCall" {
  let json : Json = {
    "type": "computer_call",
    "id": "comp_call_001",
    "action": { "type": "click", "button": "left", "x": 100, "y": 200 },
    "call_id": "call_comp_001",
    "pending_safety_checks": [],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ComputerCall(_) else { fail("Expected ComputerCall variant") }
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="comp_call_001")
  json_inspect(obj["type"], content="computer_call")
}

///|
test "ResponseOutputItem::ComputerCall_with_screenshot_action" {
  let json : Json = {
    "type": "computer_call",
    "id": "comp_call_002",
    "action": { "type": "screenshot" },
    "call_id": "call_comp_002",
    "pending_safety_checks": [{ "id": "check_001", "code": "dangerous_action" }],
    "status": "in_progress",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ComputerCall(_) else { fail("Expected ComputerCall variant") }
}

///|
test "ResponseOutputItem::LocalShellCall" {
  let json : Json = {
    "type": "local_shell_call",
    "id": "local_shell_001",
    "action": {
      "type": "exec",
      "command": ["ls", "-la"],
      "env": { "PATH": "/usr/bin" },
    },
    "call_id": "call_local_001",
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is LocalShellCall(_) else {
    fail("Expected LocalShellCall variant")
  }
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="local_shell_001")
  json_inspect(obj["type"], content="local_shell_call")
}

///|
test "ResponseOutputItem::LocalShellCall_with_options" {
  let json : Json = {
    "type": "local_shell_call",
    "id": "local_shell_002",
    "action": {
      "type": "exec",
      "command": ["pwd"],
      "env": {},
      "timeout_ms": "5000",
      "user": "root",
      "working_directory": "/tmp",
    },
    "call_id": "call_local_002",
    "status": "in_progress",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is LocalShellCall(_) else {
    fail("Expected LocalShellCall variant")
  }
}

///|
test "ResponseOutputItem::ShellCallOutput" {
  let json : Json = {
    "type": "shell_call_output",
    "id": "shell_out_001",
    "call_id": "call_shell_001",
    "max_output_length": 4096,
    "output": [
      {
        "outcome": { "type": "exit", "exit_code": 0 },
        "stderr": "",
        "stdout": "Hello world\n",
      },
    ],
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ShellCallOutput(_) else {
    fail("Expected ShellCallOutput variant")
  }
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="shell_out_001")
  json_inspect(obj["type"], content="shell_call_output")
}

///|
test "ResponseOutputItem::ShellCallOutput_timeout" {
  let json : Json = {
    "type": "shell_call_output",
    "id": "shell_out_002",
    "call_id": "call_shell_002",
    "max_output_length": 1024,
    "output": [
      {
        "outcome": { "type": "timeout" },
        "stderr": "Operation timed out",
        "stdout": "",
      },
    ],
    "created_by": "user_123",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ShellCallOutput(_) else {
    fail("Expected ShellCallOutput variant")
  }
}

///|
test "ResponseOutputItem::ApplyPatchCallOutput" {
  let json : Json = {
    "type": "apply_patch_call_output",
    "id": "patch_out_001",
    "call_id": "call_patch_001",
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ApplyPatchCallOutput(_) else {
    fail("Expected ApplyPatchCallOutput variant")
  }
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="patch_out_001")
  json_inspect(obj["type"], content="apply_patch_call_output")
}

///|
test "ResponseOutputItem::ApplyPatchCallOutput_failed" {
  let json : Json = {
    "type": "apply_patch_call_output",
    "id": "patch_out_002",
    "call_id": "call_patch_002",
    "status": "failed",
    "output": "Patch conflict detected",
    "created_by": "system",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ApplyPatchCallOutput(_) else {
    fail("Expected ApplyPatchCallOutput variant")
  }
}

///|
test "ResponseOutputItem::McpApprovalRequest" {
  let json : Json = {
    "type": "mcp_approval_request",
    "id": "mcp_approval_001",
    "arguments": "{\"path\": \"/etc/passwd\"}",
    "name": "read_file",
    "server_label": "file_server",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is McpApprovalRequest(_) else {
    fail("Expected McpApprovalRequest variant")
  }
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="mcp_approval_001")
  json_inspect(obj["type"], content="mcp_approval_request")
  json_inspect(obj["name"], content="read_file")
}

///|
test "ResponseOutputItem::CustomToolCall" {
  let json : Json = {
    "type": "custom_tool_call",
    "call_id": "call_custom_001",
    "input": "{\"query\": \"test\"}",
    "name": "my_custom_tool",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is CustomToolCall(_) else {
    fail("Expected CustomToolCall variant")
  }
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["name"], content="my_custom_tool")
  json_inspect(obj["type"], content="custom_tool_call")
}

///|
test "ResponseOutputItem::CustomToolCall_with_id" {
  let json : Json = {
    "type": "custom_tool_call",
    "call_id": "call_custom_002",
    "input": "{}",
    "name": "another_tool",
    "id": "custom_tool_id_001",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is CustomToolCall(_) else {
    fail("Expected CustomToolCall variant")
  }
}

// ============ Additional Edge Cases ============

///|
test "ResponseOutputItem::CodeInterpreterCall_with_image_output" {
  let json : Json = {
    "type": "code_interpreter_call",
    "id": "ci_img_001",
    "code": "import matplotlib; matplotlib.pyplot.savefig('plot.png')",
    "container_id": "container_456",
    "outputs": [
      { "type": "logs", "logs": "Plot saved\n" },
      { "type": "image", "url": "https://example.com/plot.png" },
    ],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is CodeInterpreterCall(_) else {
    fail("Expected CodeInterpreterCall variant")
  }
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="ci_img_001")
}

///|
test "ResponseOutputItem::FileSearchCall_with_detailed_results" {
  let json : Json = {
    "type": "file_search_call",
    "id": "fs_detailed_001",
    "queries": ["machine learning basics", "neural network architecture"],
    "status": "completed",
    "results": [
      {
        "file_id": "file_ml_001",
        "filename": "ml_basics.pdf",
        "score": 0.98,
        "text": "Machine learning is a subset of artificial intelligence...",
        "attributes": { "page": 1, "section": "Introduction" },
      },
      {
        "file_id": "file_nn_002",
        "filename": "neural_networks.pdf",
        "score": 0.85,
        "text": "Neural networks are computing systems inspired by biological neural networks...",
        "attributes": { "page": 5, "section": "Overview" },
      },
    ],
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is FileSearchCall(_) else {
    fail("Expected FileSearchCall variant")
  }
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  guard obj["results"] is Array(results) else { fail("Expected results array") }
  json_inspect(results.length(), content=2)
}

///|
test "ResponseOutputItem::ComputerCall_scroll_action" {
  let json : Json = {
    "type": "computer_call",
    "id": "comp_scroll_001",
    "action": {
      "type": "scroll",
      "x": 500,
      "y": 300,
      "scroll_x": 0,
      "scroll_y": 100,
    },
    "call_id": "call_scroll_001",
    "pending_safety_checks": [],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ComputerCall(_) else { fail("Expected ComputerCall variant") }
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="comp_scroll_001")
}

///|
test "ResponseOutputItem::ComputerCall_keypress_action" {
  let json : Json = {
    "type": "computer_call",
    "id": "comp_key_001",
    "action": { "type": "keypress", "keys": ["ctrl", "c"] },
    "call_id": "call_key_001",
    "pending_safety_checks": [],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ComputerCall(_) else { fail("Expected ComputerCall variant") }
}

///|
test "ResponseOutputItem::ComputerCall_type_action" {
  let json : Json = {
    "type": "computer_call",
    "id": "comp_type_001",
    "action": { "type": "type", "text": "Hello, World!" },
    "call_id": "call_type_001",
    "pending_safety_checks": [],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ComputerCall(_) else { fail("Expected ComputerCall variant") }
}

///|
test "ResponseOutputItem::ComputerCall_wait_action" {
  let json : Json = {
    "type": "computer_call",
    "id": "comp_wait_001",
    "action": { "type": "wait" },
    "call_id": "call_wait_001",
    "pending_safety_checks": [],
    "status": "in_progress",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ComputerCall(_) else { fail("Expected ComputerCall variant") }
}

///|
test "ResponseOutputItem::ComputerCall_drag_action" {
  let json : Json = {
    "type": "computer_call",
    "id": "comp_drag_001",
    "action": {
      "type": "drag",
      "path": [
        { "x": 100, "y": 100 },
        { "x": 300, "y": 300 },
        { "x": 500, "y": 500 },
      ],
    },
    "call_id": "call_drag_001",
    "pending_safety_checks": [],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ComputerCall(_) else { fail("Expected ComputerCall variant") }
}

///|
test "ResponseOutputItem::ComputerCall_double_click_action" {
  let json : Json = {
    "type": "computer_call",
    "id": "comp_dblclick_001",
    "action": { "type": "double_click", "x": 250, "y": 250 },
    "call_id": "call_dblclick_001",
    "pending_safety_checks": [],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ComputerCall(_) else { fail("Expected ComputerCall variant") }
}

// ============ Message Content Types ============

///|
test "ResponseOutputItem::Message_with_refusal" {
  let json : Json = {
    "type": "message",
    "id": "msg_refusal_001",
    "role": "assistant",
    "content": [
      { "type": "refusal", "refusal": "I cannot help with that request." },
    ],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is Message(_) else { fail("Expected Message variant") }
}

///|
test "ResponseOutputItem::Message_with_multiple_content" {
  let json : Json = {
    "type": "message",
    "id": "msg_multi_001",
    "role": "assistant",
    "content": [
      { "type": "output_text", "text": "Here is some text.", "annotations": [] },
      {
        "type": "output_text",
        "text": "And some more text.",
        "annotations": [],
      },
    ],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is Message(msg) else { fail("Expected Message variant") }
  let output_json = msg.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  guard obj["content"] is Array(arr) else { fail("Expected content array") }
  json_inspect(arr.length(), content=2)
}

///|
test "ResponseOutputItem::Message_with_annotations" {
  let json : Json = {
    "type": "message",
    "id": "msg_annotated_001",
    "role": "assistant",
    "content": [
      {
        "type": "output_text",
        "text": "Check out this article [1].",
        "annotations": [
          {
            "type": "url_citation",
            "start_index": 19,
            "end_index": 22,
            "title": "Example Article",
            "url": "https://example.com/article",
          },
        ],
      },
    ],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is Message(_) else { fail("Expected Message variant") }
}

///|
test "ResponseOutputItem::McpCall_with_output" {
  let json : Json = {
    "type": "mcp_call",
    "id": "mcp_output_001",
    "name": "database_query",
    "server_label": "db_server",
    "arguments": "{\"query\": \"SELECT * FROM users\"}",
    "output": "{\"rows\": [{\"id\": 1, \"name\": \"John\"}]}",
    "error": None,
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is McpCall(_) else { fail("Expected McpCall variant") }
}

///|
test "ResponseOutputItem::McpCall_with_error" {
  let json : Json = {
    "type": "mcp_call",
    "id": "mcp_error_001",
    "name": "failing_tool",
    "server_label": "broken_server",
    "arguments": "{}",
    "error": "Connection refused",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is McpCall(_) else { fail("Expected McpCall variant") }
}

///|
test "ResponseOutputItem::McpListTools_with_tools" {
  let json : Json = {
    "type": "mcp_list_tools",
    "id": "mcp_list_full_001",
    "server_label": "my_mcp_server",
    "tools": [
      { "name": "tool_1", "description": "First tool", "input_schema": {} },
      {
        "name": "tool_2",
        "description": "Second tool",
        "input_schema": { "type": "object" },
      },
    ],
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is McpListTools(_) else { fail("Expected McpListTools variant") }
}

///|
test "ResponseOutputItem::ImageGenerationCall_with_revised_prompt" {
  let json : Json = {
    "type": "image_generation_call",
    "id": "img_revised_001",
    "result": "base64_image_data",
    "revised_prompt": "A photorealistic image of a sunset over mountains",
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is ImageGenerationCall(_) else {
    fail("Expected ImageGenerationCall variant")
  }
}

///|
test "ResponseOutputItem::FunctionCall_in_progress" {
  let json : Json = {
    "type": "function_call",
    "call_id": "call_inprog_001",
    "name": "long_running_task",
    "arguments": "{}",
    "status": "in_progress",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is FunctionCall(call) else {
    fail("Expected FunctionCall variant")
  }
  guard call.status is Some(status) else { fail("Expected Some status") }
  json_inspect(status.to_json(), content="in_progress")
}

///|
test "ResponseOutputItem::FunctionCall_incomplete" {
  let json : Json = {
    "type": "function_call",
    "call_id": "call_incomplete_001",
    "name": "interrupted_task",
    "arguments": "{\"partial\": true}",
    "status": "incomplete",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is FunctionCall(call) else {
    fail("Expected FunctionCall variant")
  }
  guard call.status is Some(status) else { fail("Expected Some status") }
  json_inspect(status.to_json(), content="incomplete")
}

// ============ Code Interpreter Output Types ============

///|
test "ResponseOutputItem::CodeInterpreterCall_logs_and_image_outputs" {
  let json : Json = {
    "type": "code_interpreter_call",
    "id": "ci_img_output_001",
    "code": "import matplotlib.pyplot as plt; plt.savefig('plot.png')",
    "container_id": "container_789",
    "outputs": [
      { "type": "logs", "logs": "Plot saved\n" },
      { "type": "image", "url": "https://example.com/outputs/plot.png" },
    ],
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is CodeInterpreterCall(_) else {
    fail("Expected CodeInterpreterCall variant")
  }
}

// ============ WebSearch Results ============

///|
test "ResponseOutputItem::WebSearchCall_with_sources" {
  let json : Json = {
    "type": "web_search_call",
    "id": "ws_sources_001",
    "action": {
      "type": "search",
      "query": "MoonBit programming language",
      "sources": [
        { "type": "url", "url": "https://moonbitlang.com" },
        { "type": "url", "url": "https://example.com/moonbit" },
      ],
    },
    "status": "completed",
  }
  let item : @responses.ResponseOutputItem = @json.from_json(json)
  guard item is WebSearchCall(_) else { fail("Expected WebSearchCall variant") }
}
