///|
/// Tests for ResponseStreamEvent variants

// Helper function to create a minimal Response JSON object
fn minimal_response_json() -> Json {
  {
    "id": "resp_123",
    "created_at": 1234567890.0,
    "error": { "code": "server_error", "message": "" },
    "incomplete_details": { "reason": "max_output_tokens" },
    "instructions": "You are helpful",
    "metadata": {},
    "model": "gpt-4o",
    "object": "response",
    "output": [],
    "parallel_tool_calls": true,
    "temperature": 0.7,
    "tool_choice": "auto",
    "tools": [],
    "top_p": 1.0,
    "prompt_cache_key": "",
    "safety_identifier": "",
    "status": "completed",
    "text": { "format": { "type": "text" } },
    "usage": {
      "input_tokens": 10,
      "input_tokens_details": { "cached_tokens": 0 },
      "output_tokens": 20,
      "output_tokens_details": { "reasoning_tokens": 0 },
      "total_tokens": 30,
    },
  }
}

///|
test "ResponseStreamEvent::Created" {
  let json : Json = {
    "type": "response.created",
    "response": minimal_response_json(),
    "sequence_number": 1,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is Created(_) else { fail("Expected Created variant") }
}

///|
test "ResponseStreamEvent::Completed" {
  let json : Json = {
    "type": "response.completed",
    "response": minimal_response_json(),
    "sequence_number": 10,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is Completed(_) else { fail("Expected Completed variant") }
}

///|
test "ResponseStreamEvent::InProgress" {
  let json : Json = {
    "type": "response.in_progress",
    "response": minimal_response_json(),
    "sequence_number": 2,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is InProgress(_) else { fail("Expected InProgress variant") }
}

///|
test "ResponseStreamEvent::Failed" {
  let json : Json = {
    "type": "response.failed",
    "response": minimal_response_json(),
    "sequence_number": 5,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is Failed(_) else { fail("Expected Failed variant") }
}

///|
test "ResponseStreamEvent::Incomplete" {
  let json : Json = {
    "type": "response.incomplete",
    "response": minimal_response_json(),
    "sequence_number": 8,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is Incomplete(_) else { fail("Expected Incomplete variant") }
}

///|
test "ResponseStreamEvent::Queued" {
  let json : Json = {
    "type": "response.queued",
    "response": minimal_response_json(),
    "sequence_number": 0,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is Queued(_) else { fail("Expected Queued variant") }
}

///|
test "ResponseStreamEvent::OutputTextDelta" {
  let json : Json = {
    "type": "response.output_text.delta",
    "content_index": 0,
    "delta": "Hello",
    "item_id": "item_001",
    "logprobs": [],
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is OutputTextDelta(_) else {
    fail("Expected OutputTextDelta variant")
  }
}

///|
test "ResponseStreamEvent::OutputTextDone" {
  let json : Json = {
    "type": "response.output_text.done",
    "content_index": 0,
    "item_id": "item_001",
    "logprobs": [],
    "output_index": 0,
    "sequence_number": 5,
    "text": "Hello, world!",
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is OutputTextDone(_) else {
    fail("Expected OutputTextDone variant")
  }
}

///|
test "ResponseStreamEvent::FunctionCallArgumentsDelta" {
  let json : Json = {
    "type": "response.function_call_arguments.delta",
    "delta": "{\"loc",
    "item_id": "func_001",
    "output_index": 0,
    "sequence_number": 4,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is FunctionCallArgumentsDelta(_) else {
    fail("Expected FunctionCallArgumentsDelta variant")
  }
}

///|
test "ResponseStreamEvent::FunctionCallArgumentsDone" {
  let json : Json = {
    "type": "response.function_call_arguments.done",
    "arguments": "{\"location\": \"San Francisco\"}",
    "item_id": "func_001",
    "name": "get_weather",
    "output_index": 0,
    "sequence_number": 6,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is FunctionCallArgumentsDone(_) else {
    fail("Expected FunctionCallArgumentsDone variant")
  }
}

///|
test "ResponseStreamEvent::Error" {
  let json : Json = {
    "type": "error",
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded",
    "param": "",
    "sequence_number": 1,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is Error(_) else { fail("Expected Error variant") }
}

///|
test "ResponseStreamEvent::invalid_type" {
  let json : Json = { "type": "invalid.event.type" }
  let result = try {
    let _ : @responses.ResponseStreamEvent = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ Audio Events ============

///|
test "ResponseStreamEvent::AudioDelta" {
  let json : Json = {
    "type": "response.audio.delta",
    "delta": "base64_audio_data",
    "sequence_number": 1,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is AudioDelta(_) else { fail("Expected AudioDelta variant") }
}

///|
test "ResponseStreamEvent::AudioDone" {
  let json : Json = { "type": "response.audio.done", "sequence_number": 5 }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is AudioDone(_) else { fail("Expected AudioDone variant") }
}

///|
test "ResponseStreamEvent::AudioTranscriptDelta" {
  let json : Json = {
    "type": "response.audio.transcript.delta",
    "delta": "Hello",
    "sequence_number": 2,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is AudioTranscriptDelta(_) else {
    fail("Expected AudioTranscriptDelta variant")
  }
}

///|
test "ResponseStreamEvent::AudioTranscriptDone" {
  let json : Json = {
    "type": "response.audio.transcript.done",
    "sequence_number": 6,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is AudioTranscriptDone(_) else {
    fail("Expected AudioTranscriptDone variant")
  }
}

// ============ Reasoning Events ============

///|
test "ResponseStreamEvent::ReasoningTextDelta" {
  let json : Json = {
    "type": "response.reasoning_text.delta",
    "content_index": 0,
    "delta": "Let me think...",
    "item_id": "reason_001",
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ReasoningTextDelta(_) else {
    fail("Expected ReasoningTextDelta variant")
  }
}

///|
test "ResponseStreamEvent::ReasoningTextDone" {
  let json : Json = {
    "type": "response.reasoning_text.done",
    "content_index": 0,
    "item_id": "reason_001",
    "output_index": 0,
    "sequence_number": 5,
    "text": "Complete reasoning here",
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ReasoningTextDone(_) else {
    fail("Expected ReasoningTextDone variant")
  }
}

///|
test "ResponseStreamEvent::ReasoningSummaryTextDelta" {
  let json : Json = {
    "type": "response.reasoning_summary_text.delta",
    "delta": "Summary...",
    "item_id": "reason_002",
    "output_index": 0,
    "sequence_number": 4,
    "summary_index": 0,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ReasoningSummaryTextDelta(_) else {
    fail("Expected ReasoningSummaryTextDelta variant")
  }
}

///|
test "ResponseStreamEvent::ReasoningSummaryTextDone" {
  let json : Json = {
    "type": "response.reasoning_summary_text.done",
    "item_id": "reason_002",
    "output_index": 0,
    "sequence_number": 6,
    "summary_index": 0,
    "text": "Complete summary",
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ReasoningSummaryTextDone(_) else {
    fail("Expected ReasoningSummaryTextDone variant")
  }
}

///|
test "ResponseStreamEvent::ReasoningSummaryPartAdded" {
  let json : Json = {
    "type": "response.reasoning_summary_part.added",
    "item_id": "reason_003",
    "output_index": 0,
    "part": { "type": "summary_text", "text": "" },
    "sequence_number": 2,
    "summary_index": 0,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ReasoningSummaryPartAdded(_) else {
    fail("Expected ReasoningSummaryPartAdded variant")
  }
}

///|
test "ResponseStreamEvent::ReasoningSummaryPartDone" {
  let json : Json = {
    "type": "response.reasoning_summary_part.done",
    "item_id": "reason_003",
    "output_index": 0,
    "part": { "type": "summary_text", "text": "Done" },
    "sequence_number": 7,
    "summary_index": 0,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ReasoningSummaryPartDone(_) else {
    fail("Expected ReasoningSummaryPartDone variant")
  }
}

// ============ Refusal Events ============

///|
test "ResponseStreamEvent::RefusalDelta" {
  let json : Json = {
    "type": "response.refusal.delta",
    "content_index": 0,
    "delta": "I cannot",
    "item_id": "msg_001",
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is RefusalDelta(_) else { fail("Expected RefusalDelta variant") }
}

///|
test "ResponseStreamEvent::RefusalDone" {
  let json : Json = {
    "type": "response.refusal.done",
    "content_index": 0,
    "item_id": "msg_001",
    "output_index": 0,
    "refusal": "I cannot help with that request.",
    "sequence_number": 5,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is RefusalDone(_) else { fail("Expected RefusalDone variant") }
}

// ============ Code Interpreter Events ============

///|
test "ResponseStreamEvent::CodeInterpreterCallInProgress" {
  let json : Json = {
    "type": "response.code_interpreter_call.in_progress",
    "item_id": "ci_001",
    "output_index": 0,
    "sequence_number": 2,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is CodeInterpreterCallInProgress(_) else {
    fail("Expected CodeInterpreterCallInProgress variant")
  }
}

///|
test "ResponseStreamEvent::CodeInterpreterCallInterpreting" {
  let json : Json = {
    "type": "response.code_interpreter_call.interpreting",
    "item_id": "ci_001",
    "output_index": 0,
    "sequence_number": 4,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is CodeInterpreterCallInterpreting(_) else {
    fail("Expected CodeInterpreterCallInterpreting variant")
  }
}

///|
test "ResponseStreamEvent::CodeInterpreterCallCompleted" {
  let json : Json = {
    "type": "response.code_interpreter_call.completed",
    "item_id": "ci_001",
    "output_index": 0,
    "sequence_number": 6,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is CodeInterpreterCallCompleted(_) else {
    fail("Expected CodeInterpreterCallCompleted variant")
  }
}

///|
test "ResponseStreamEvent::CodeInterpreterCallCodeDelta" {
  let json : Json = {
    "type": "response.code_interpreter_call_code.delta",
    "delta": "print(",
    "item_id": "ci_001",
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is CodeInterpreterCallCodeDelta(_) else {
    fail("Expected CodeInterpreterCallCodeDelta variant")
  }
}

///|
test "ResponseStreamEvent::CodeInterpreterCallCodeDone" {
  let json : Json = {
    "type": "response.code_interpreter_call_code.done",
    "code": "print('hello')",
    "item_id": "ci_001",
    "output_index": 0,
    "sequence_number": 5,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is CodeInterpreterCallCodeDone(_) else {
    fail("Expected CodeInterpreterCallCodeDone variant")
  }
}

// ============ File Search Events ============

///|
test "ResponseStreamEvent::FileSearchCallInProgress" {
  let json : Json = {
    "type": "response.file_search_call.in_progress",
    "item_id": "fs_001",
    "output_index": 0,
    "sequence_number": 2,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is FileSearchCallInProgress(_) else {
    fail("Expected FileSearchCallInProgress variant")
  }
}

///|
test "ResponseStreamEvent::FileSearchCallSearching" {
  let json : Json = {
    "type": "response.file_search_call.searching",
    "item_id": "fs_001",
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is FileSearchCallSearching(_) else {
    fail("Expected FileSearchCallSearching variant")
  }
}

///|
test "ResponseStreamEvent::FileSearchCallCompleted" {
  let json : Json = {
    "type": "response.file_search_call.completed",
    "item_id": "fs_001",
    "output_index": 0,
    "sequence_number": 5,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is FileSearchCallCompleted(_) else {
    fail("Expected FileSearchCallCompleted variant")
  }
}

// ============ Web Search Events ============

///|
test "ResponseStreamEvent::WebSearchCallInProgress" {
  let json : Json = {
    "type": "response.web_search_call.in_progress",
    "item_id": "ws_001",
    "output_index": 0,
    "sequence_number": 2,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is WebSearchCallInProgress(_) else {
    fail("Expected WebSearchCallInProgress variant")
  }
}

///|
test "ResponseStreamEvent::WebSearchCallSearching" {
  let json : Json = {
    "type": "response.web_search_call.searching",
    "item_id": "ws_001",
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is WebSearchCallSearching(_) else {
    fail("Expected WebSearchCallSearching variant")
  }
}

///|
test "ResponseStreamEvent::WebSearchCallCompleted" {
  let json : Json = {
    "type": "response.web_search_call.completed",
    "item_id": "ws_001",
    "output_index": 0,
    "sequence_number": 5,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is WebSearchCallCompleted(_) else {
    fail("Expected WebSearchCallCompleted variant")
  }
}

// ============ Image Generation Events ============

///|
test "ResponseStreamEvent::ImageGenerationCallInProgress" {
  let json : Json = {
    "type": "response.image_generation_call.in_progress",
    "item_id": "img_001",
    "output_index": 0,
    "sequence_number": 2,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ImageGenerationCallInProgress(_) else {
    fail("Expected ImageGenerationCallInProgress variant")
  }
}

///|
test "ResponseStreamEvent::ImageGenerationCallGenerating" {
  let json : Json = {
    "type": "response.image_generation_call.generating",
    "item_id": "img_001",
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ImageGenerationCallGenerating(_) else {
    fail("Expected ImageGenerationCallGenerating variant")
  }
}

///|
test "ResponseStreamEvent::ImageGenerationCallPartialImage" {
  let json : Json = {
    "type": "response.image_generation_call.partial_image",
    "item_id": "img_001",
    "output_index": 0,
    "partial_image_b64": "base64_data",
    "partial_image_index": 0,
    "sequence_number": 4,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ImageGenerationCallPartialImage(_) else {
    fail("Expected ImageGenerationCallPartialImage variant")
  }
}

///|
test "ResponseStreamEvent::ImageGenerationCallCompleted" {
  let json : Json = {
    "type": "response.image_generation_call.completed",
    "item_id": "img_001",
    "output_index": 0,
    "sequence_number": 6,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ImageGenerationCallCompleted(_) else {
    fail("Expected ImageGenerationCallCompleted variant")
  }
}

// ============ Content Part Events ============

///|
test "ResponseStreamEvent::ContentPartAdded" {
  let json : Json = {
    "type": "response.content_part.added",
    "content_index": 0,
    "item_id": "msg_001",
    "output_index": 0,
    "part": { "type": "output_text", "text": "", "annotations": [] },
    "sequence_number": 2,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ContentPartAdded(_) else {
    fail("Expected ContentPartAdded variant")
  }
}

///|
test "ResponseStreamEvent::ContentPartDone" {
  let json : Json = {
    "type": "response.content_part.done",
    "content_index": 0,
    "item_id": "msg_001",
    "output_index": 0,
    "part": { "type": "output_text", "text": "Hello!", "annotations": [] },
    "sequence_number": 5,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is ContentPartDone(_) else {
    fail("Expected ContentPartDone variant")
  }
}

///|
test "ResponseStreamEvent::OutputItemAdded" {
  let json : Json = {
    "type": "response.output_item.added",
    "item": {
      "type": "message",
      "id": "msg_001",
      "role": "assistant",
      "content": [],
      "status": "in_progress",
    },
    "output_index": 0,
    "sequence_number": 1,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is OutputItemAdded(_) else {
    fail("Expected OutputItemAdded variant")
  }
}

///|
test "ResponseStreamEvent::OutputItemDone" {
  let json : Json = {
    "type": "response.output_item.done",
    "item": {
      "type": "message",
      "id": "msg_001",
      "role": "assistant",
      "content": [{ "type": "output_text", "text": "Done!", "annotations": [] }],
      "status": "completed",
    },
    "output_index": 0,
    "sequence_number": 10,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is OutputItemDone(_) else {
    fail("Expected OutputItemDone variant")
  }
}

// ============ MCP Events ============

///|
test "ResponseStreamEvent::McpCallInProgress" {
  let json : Json = {
    "type": "response.mcp_call.in_progress",
    "item_id": "mcp_001",
    "output_index": 0,
    "sequence_number": 2,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is McpCallInProgress(_) else {
    fail("Expected McpCallInProgress variant")
  }
}

///|
test "ResponseStreamEvent::McpCallArgumentsDelta" {
  let json : Json = {
    "type": "response.mcp_call_arguments.delta",
    "delta": "{\"key\":",
    "item_id": "mcp_001",
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is McpCallArgumentsDelta(_) else {
    fail("Expected McpCallArgumentsDelta variant")
  }
}

///|
test "ResponseStreamEvent::McpCallArgumentsDone" {
  let json : Json = {
    "type": "response.mcp_call_arguments.done",
    "arguments": "{\"key\": \"value\"}",
    "item_id": "mcp_001",
    "output_index": 0,
    "sequence_number": 4,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is McpCallArgumentsDone(_) else {
    fail("Expected McpCallArgumentsDone variant")
  }
}

///|
test "ResponseStreamEvent::McpCallCompleted" {
  let json : Json = {
    "type": "response.mcp_call.completed",
    "item_id": "mcp_001",
    "output_index": 0,
    "sequence_number": 6,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is McpCallCompleted(_) else {
    fail("Expected McpCallCompleted variant")
  }
}

///|
test "ResponseStreamEvent::McpCallFailed" {
  let json : Json = {
    "type": "response.mcp_call.failed",
    "item_id": "mcp_002",
    "output_index": 0,
    "sequence_number": 5,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is McpCallFailed(_) else {
    fail("Expected McpCallFailed variant")
  }
}

///|
test "ResponseStreamEvent::McpListToolsInProgress" {
  let json : Json = {
    "type": "response.mcp_list_tools.in_progress",
    "item_id": "mcp_list_001",
    "output_index": 0,
    "sequence_number": 2,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is McpListToolsInProgress(_) else {
    fail("Expected McpListToolsInProgress variant")
  }
}

///|
test "ResponseStreamEvent::McpListToolsCompleted" {
  let json : Json = {
    "type": "response.mcp_list_tools.completed",
    "item_id": "mcp_list_001",
    "output_index": 0,
    "sequence_number": 4,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is McpListToolsCompleted(_) else {
    fail("Expected McpListToolsCompleted variant")
  }
}

///|
test "ResponseStreamEvent::McpListToolsFailed" {
  let json : Json = {
    "type": "response.mcp_list_tools.failed",
    "item_id": "mcp_list_002",
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is McpListToolsFailed(_) else {
    fail("Expected McpListToolsFailed variant")
  }
}

// ============ Custom Tool Call Input Events ============

///|
test "ResponseStreamEvent::CustomToolCallInputDelta" {
  let json : Json = {
    "type": "response.custom_tool_call_input.delta",
    "delta": "{\"key\":",
    "item_id": "custom_001",
    "output_index": 0,
    "sequence_number": 3,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is CustomToolCallInputDelta(_) else {
    fail("Expected CustomToolCallInputDelta variant")
  }
}

///|
test "ResponseStreamEvent::CustomToolCallInputDone" {
  let json : Json = {
    "type": "response.custom_tool_call_input.done",
    "input": "{\"key\": \"value\"}",
    "item_id": "custom_001",
    "output_index": 0,
    "sequence_number": 4,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is CustomToolCallInputDone(_) else {
    fail("Expected CustomToolCallInputDone variant")
  }
}

// ============ Output Text Annotation Events ============

///|
test "ResponseStreamEvent::OutputTextAnnotationAdded" {
  let json : Json = {
    "type": "response.output_text.annotation.added",
    "annotation": {
      "type": "url_citation",
      "url": "https://example.com",
      "title": "Example",
    },
    "annotation_index": 0,
    "content_index": 0,
    "item_id": "msg_001",
    "output_index": 0,
    "sequence_number": 5,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is OutputTextAnnotationAdded(_) else {
    fail("Expected OutputTextAnnotationAdded variant")
  }
}

///|
test "ResponseStreamEvent::OutputTextAnnotationAdded_file_citation" {
  let json : Json = {
    "type": "response.output_text.annotation.added",
    "annotation": {
      "type": "file_citation",
      "file_id": "file_123",
      "filename": "doc.pdf",
      "index": 0,
    },
    "annotation_index": 1,
    "content_index": 0,
    "item_id": "msg_002",
    "output_index": 0,
    "sequence_number": 6,
  }
  let event : @responses.ResponseStreamEvent = @json.from_json(json)
  guard event is OutputTextAnnotationAdded(_) else {
    fail("Expected OutputTextAnnotationAdded variant")
  }
}
