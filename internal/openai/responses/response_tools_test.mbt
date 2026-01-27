///|
/// Tests for Tool variants

///|
test "Tool::Function" {
  let json : Json = {
    "type": "function",
    "name": "get_weather",
    "parameters": { "type": "object" },
    "strict": true,
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is Function(_) else { fail("Expected Function variant") }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["name"], content="get_weather")
}

///|
test "Tool::Function_with_description" {
  let json : Json = {
    "type": "function",
    "name": "search_docs",
    "parameters": { "type": "object", "properties": {} },
    "strict": false,
    "description": "Search the documentation",
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is Function(_) else { fail("Expected Function variant") }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj.get("description") is Some(_), content=true)
}

///|
test "Tool::FileSearch" {
  let json : Json = {
    "type": "file_search",
    "vector_store_ids": ["vs_123", "vs_456"],
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is FileSearch(_) else { fail("Expected FileSearch variant") }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="file_search")
}

///|
test "Tool::FileSearch_with_options" {
  let json : Json = {
    "type": "file_search",
    "vector_store_ids": ["vs_789"],
    "max_num_results": "10",
    "ranking_options": { "score_threshold": 0.5 },
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is FileSearch(_) else { fail("Expected FileSearch variant") }
}

///|
test "Tool::ComputerUsePreview" {
  let json : Json = {
    "type": "computer_use_preview",
    "display_height": 1080,
    "display_width": 1920,
    "environment": "browser",
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is ComputerUsePreview(_) else {
    fail("Expected ComputerUsePreview variant")
  }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["environment"], content="browser")
}

///|
test "Tool::WebSearch" {
  let json : Json = { "type": "web_search" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is WebSearch(_) else { fail("Expected WebSearch variant") }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="web_search")
}

///|
test "Tool::WebSearch_2025_08_26" {
  let json : Json = { "type": "web_search_2025_08_26" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is WebSearch(_) else { fail("Expected WebSearch variant") }
}

///|
test "Tool::WebSearch_with_options" {
  let json : Json = {
    "type": "web_search",
    "search_context_size": "medium",
    "user_location": { "city": "San Francisco", "country": "US" },
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is WebSearch(_) else { fail("Expected WebSearch variant") }
}

///|
test "Tool::Mcp" {
  let json : Json = { "type": "mcp", "server_label": "my_mcp_server" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is Mcp(_) else { fail("Expected Mcp variant") }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["server_label"], content="my_mcp_server")
}

///|
test "Tool::Mcp_with_options" {
  let json : Json = {
    "type": "mcp",
    "server_label": "my_server",
    "server_url": "https://example.com/mcp",
    "allowed_tools": ["tool1", "tool2"],
    "require_approval": "always",
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is Mcp(_) else { fail("Expected Mcp variant") }
}

///|
test "Tool::CodeInterpreter_with_container_id" {
  let json : Json = { "type": "code_interpreter", "container": "container_123" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is CodeInterpreter(_) else {
    fail("Expected CodeInterpreter variant")
  }
}

///|
test "Tool::CodeInterpreter_with_auto_container" {
  let json : Json = {
    "type": "code_interpreter",
    "container": { "type": "auto", "file_ids": ["file_123"] },
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is CodeInterpreter(_) else {
    fail("Expected CodeInterpreter variant")
  }
}

///|
test "Tool::ImageGeneration" {
  let json : Json = { "type": "image_generation" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is ImageGeneration(_) else {
    fail("Expected ImageGeneration variant")
  }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="image_generation")
}

///|
test "Tool::ImageGeneration_with_options" {
  let json : Json = {
    "type": "image_generation",
    "quality": "high",
    "size": "1024x1024",
    "model": "dall-e-3",
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is ImageGeneration(_) else {
    fail("Expected ImageGeneration variant")
  }
}

///|
test "Tool::LocalShell" {
  let json : Json = { "type": "local_shell" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is LocalShell(_) else { fail("Expected LocalShell variant") }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="local_shell")
}

///|
test "Tool::Shell" {
  let json : Json = { "type": "shell" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is Shell(_) else { fail("Expected Shell variant") }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="shell")
}

///|
test "Tool::Custom" {
  let json : Json = { "type": "custom", "name": "my_custom_tool" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is Custom(_) else { fail("Expected Custom variant") }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["name"], content="my_custom_tool")
}

///|
test "Tool::Custom_with_description" {
  let json : Json = {
    "type": "custom",
    "name": "custom_tool",
    "description": "A custom tool for testing",
  }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is Custom(_) else { fail("Expected Custom variant") }
}

///|
test "Tool::WebSearchPreview" {
  let json : Json = { "type": "web_search_preview" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is WebSearchPreview(_) else {
    fail("Expected WebSearchPreview variant")
  }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="web_search_preview")
}

///|
test "Tool::WebSearchPreview_2025_03_11" {
  let json : Json = { "type": "web_search_preview_2025_03_11" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is WebSearchPreview(_) else {
    fail("Expected WebSearchPreview variant")
  }
}

///|
test "Tool::ApplyPatch" {
  let json : Json = { "type": "apply_patch" }
  let tool : @responses.Tool = @json.from_json(json)
  guard tool is ApplyPatch(_) else { fail("Expected ApplyPatch variant") }
  let output_json = tool.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="apply_patch")
}

///|
test "Tool::invalid_type" {
  let json : Json = { "type": "invalid_tool_type" }
  let result = try {
    let _ : @responses.Tool = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

///|
test "ComputerToolEnvironment::all_values" {
  let environments = ["windows", "mac", "linux", "ubuntu", "browser"]
  let count = environments.length()
  json_inspect(count, content=5)
}

///|
test "WebSearchToolSearchContextSize::low" {
  let json : Json = "low"
  let size : @responses.WebSearchToolSearchContextSize = @json.from_json(json)
  json_inspect(size.to_json(), content="low")
}

///|
test "WebSearchToolSearchContextSize::medium" {
  let json : Json = "medium"
  let size : @responses.WebSearchToolSearchContextSize = @json.from_json(json)
  json_inspect(size.to_json(), content="medium")
}

///|
test "WebSearchToolSearchContextSize::high" {
  let json : Json = "high"
  let size : @responses.WebSearchToolSearchContextSize = @json.from_json(json)
  json_inspect(size.to_json(), content="high")
}
