///|
/// Tests for core Response types and JSON serialization

///|
test "ResponseStatus::completed" {
  let json : Json = "completed"
  let status : @responses.ResponseStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="completed")
}

///|
test "ResponseStatus::failed" {
  let json : Json = "failed"
  let status : @responses.ResponseStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="failed")
}

///|
test "ResponseStatus::in_progress" {
  let json : Json = "in_progress"
  let status : @responses.ResponseStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="in_progress")
}

///|
test "ResponseStatus::cancelled" {
  let json : Json = "cancelled"
  let status : @responses.ResponseStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="cancelled")
}

///|
test "ResponseStatus::queued" {
  let json : Json = "queued"
  let status : @responses.ResponseStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="queued")
}

///|
test "ResponseStatus::incomplete" {
  let json : Json = "incomplete"
  let status : @responses.ResponseStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="incomplete")
}

///|
test "ResponseErrorCode::server_error" {
  let json : Json = "server_error"
  let code : @responses.ResponseErrorCode = @json.from_json(json)
  json_inspect(code.to_json(), content="server_error")
}

///|
test "ResponseErrorCode::rate_limit_exceeded" {
  let json : Json = "rate_limit_exceeded"
  let code : @responses.ResponseErrorCode = @json.from_json(json)
  json_inspect(code.to_json(), content="rate_limit_exceeded")
}

///|
test "ResponseErrorCode::invalid_prompt" {
  let json : Json = "invalid_prompt"
  let code : @responses.ResponseErrorCode = @json.from_json(json)
  json_inspect(code.to_json(), content="invalid_prompt")
}

///|
test "ResponseError::round_trip" {
  let json : Json = { "code": "server_error", "message": "Internal error" }
  let error : @responses.ResponseError = @json.from_json(json)
  json_inspect(error.code.to_json(), content="server_error")
  json_inspect(error.message, content="Internal error")
  json_inspect(error.to_json(), content=json)
}

///|
test "ResponseIncompleteDetails::max_output_tokens" {
  let json : Json = { "reason": "max_output_tokens" }
  let details : @responses.ResponseIncompleteDetails = @json.from_json(json)
  json_inspect(details.reason.to_json(), content="max_output_tokens")
  json_inspect(details.to_json(), content=json)
}

///|
test "ResponseIncompleteDetails::content_filter" {
  let json : Json = { "reason": "content_filter" }
  let details : @responses.ResponseIncompleteDetails = @json.from_json(json)
  json_inspect(details.reason.to_json(), content="content_filter")
}

///|
test "ResponseUsage::round_trip" {
  let json : Json = {
    "input_tokens": 100,
    "input_tokens_details": { "cached_tokens": 50 },
    "output_tokens": 200,
    "output_tokens_details": { "reasoning_tokens": 25 },
    "total_tokens": 300,
  }
  let usage : @responses.ResponseUsage = @json.from_json(json)
  inspect(usage.input_tokens, content="100")
  inspect(usage.output_tokens, content="200")
  inspect(usage.total_tokens, content="300")
  inspect(usage.input_tokens_details.cached_tokens, content="50")
  inspect(usage.output_tokens_details.reasoning_tokens, content="25")
}

///|
test "ResponseInstructions::text" {
  let json : Json = "You are a helpful assistant."
  let instructions : @responses.ResponseInstructions = @json.from_json(json)
  guard instructions is Text(text) else { fail("Expected Text variant") }
  json_inspect(text, content="You are a helpful assistant.")
  json_inspect(instructions.to_json(), content=json)
}

///|
test "ResponseInstructions::input_item_list" {
  let json : Json = [{ "type": "message", "role": "user", "content": "Hello" }]
  let instructions : @responses.ResponseInstructions = @json.from_json(json)
  guard instructions is InputItemList(items) else {
    fail("Expected InputItemList variant")
  }
  json_inspect(items.length(), content=1)
}

///|
test "ResponseToolChoice::mode_none" {
  let json : Json = "none"
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Mode(_) else { fail("Expected Mode variant") }
  json_inspect(choice.to_json(), content="none")
}

///|
test "ResponseToolChoice::mode_auto" {
  let json : Json = "auto"
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Mode(_) else { fail("Expected Mode variant") }
  json_inspect(choice.to_json(), content="auto")
}

///|
test "ResponseToolChoice::mode_required" {
  let json : Json = "required"
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Mode(_) else { fail("Expected Mode variant") }
  json_inspect(choice.to_json(), content="required")
}

///|
test "ResponseToolChoice::function" {
  let json : Json = { "type": "function", "name": "get_weather" }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Function(func) else { fail("Expected Function variant") }
  json_inspect(func.name, content="get_weather")
  json_inspect(choice.to_json(), content={
    "name": "get_weather",
    "type": "function",
  })
}

///|
test "ResponseToolChoice::hosted_file_search" {
  let json : Json = { "type": "file_search" }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Hosted(hosted) else { fail("Expected Hosted variant") }
  json_inspect(hosted.type_.to_json(), content="file_search")
}

///|
test "ResponseToolChoice::mcp" {
  let json : Json = { "type": "mcp", "server_label": "my_server" }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Mcp(mcp) else { fail("Expected Mcp variant") }
  json_inspect(mcp.server_label, content="my_server")
}

///|
test "ResponseTextConfig::text_format" {
  let json : Json = { "format": { "type": "text" } }
  let config : @responses.ResponseTextConfig = @json.from_json(json)
  guard config.format is Text(_) else { fail("Expected Text format") }
  json_inspect(config.verbosity is None, content=true)
}

///|
test "ResponseTextConfig::with_verbosity" {
  let json : Json = { "format": { "type": "text" }, "verbosity": "high" }
  let config : @responses.ResponseTextConfig = @json.from_json(json)
  guard config.verbosity is Some(v) else { fail("Expected Some verbosity") }
  json_inspect(v.to_json(), content="high")
}

///|
test "ResponseTextConfig::json_schema" {
  let json : Json = {
    "format": {
      "type": "json_schema",
      "name": "my_schema",
      "schema": { "type": "object" },
    },
  }
  let config : @responses.ResponseTextConfig = @json.from_json(json)
  guard config.format is JSONSchema(schema) else {
    fail("Expected JSONSchema format")
  }
  json_inspect(schema.name, content="my_schema")
}

///|
test "ResponseOutputMessageStatus::in_progress" {
  let json : Json = "in_progress"
  let status : @responses.ResponseOutputMessageStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="in_progress")
}

///|
test "ResponseOutputMessageStatus::completed" {
  let json : Json = "completed"
  let status : @responses.ResponseOutputMessageStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="completed")
}

///|
test "ResponseOutputMessageStatus::incomplete" {
  let json : Json = "incomplete"
  let status : @responses.ResponseOutputMessageStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="incomplete")
}

///|
test "ResponseOutputText::round_trip" {
  let json : Json = {
    "type": "output_text",
    "text": "Hello, world!",
    "annotations": [],
  }
  let output : @responses.ResponseOutputText = @json.from_json(json)
  json_inspect(output.text, content="Hello, world!")
  json_inspect(output.annotations.length(), content=0)
  json_inspect(output.to_json(), content=json)
}

///|
test "ResponseOutputMessage::round_trip" {
  let json : Json = {
    "type": "message",
    "id": "msg_123",
    "role": "assistant",
    "content": [{ "type": "output_text", "text": "Hello!", "annotations": [] }],
    "status": "completed",
  }
  let message : @responses.ResponseOutputMessage = @json.from_json(json)
  json_inspect(message.id, content="msg_123")
  json_inspect(message.role.to_json(), content="assistant")
  json_inspect(message.status.to_json(), content="completed")
  json_inspect(message.content.length(), content=1)
  json_inspect(message.to_json(), content={
    "type": "message",
    "id": "msg_123",
    "content": [{ "type": "output_text", "text": "Hello!", "annotations": [] }],
    "status": "completed",
    "role": "assistant",
  })
}

///|
test "Response::minimal" {
  let json : Json = {
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
  let response : @responses.Response = @json.from_json(json)
  json_inspect(response.id, content="resp_123")
  json_inspect(response.model, content="gpt-4o")
  json_inspect(response.status.to_json(), content="completed")
  json_inspect(response.temperature, content=0.7)
  json_inspect(response.parallel_tool_calls, content=true)
  inspect(response.usage.total_tokens, content="30")
}

///|
test "Response::with_output" {
  let json : Json = {
    "id": "resp_456",
    "created_at": 1234567890.0,
    "error": { "code": "server_error", "message": "" },
    "incomplete_details": { "reason": "max_output_tokens" },
    "instructions": "Be concise",
    "metadata": {},
    "model": "gpt-4o-mini",
    "object": "response",
    "output": [
      {
        "type": "message",
        "id": "msg_001",
        "role": "assistant",
        "content": [
          {
            "type": "output_text",
            "text": "I can help you!",
            "annotations": [],
          },
        ],
        "status": "completed",
      },
    ],
    "parallel_tool_calls": false,
    "temperature": 0.5,
    "tool_choice": "none",
    "tools": [],
    "top_p": 0.9,
    "prompt_cache_key": "cache_key_123",
    "safety_identifier": "safe_123",
    "status": "completed",
    "text": { "format": { "type": "text" } },
    "usage": {
      "input_tokens": 50,
      "input_tokens_details": { "cached_tokens": 25 },
      "output_tokens": 100,
      "output_tokens_details": { "reasoning_tokens": 10 },
      "total_tokens": 150,
    },
  }
  let response : @responses.Response = @json.from_json(json)
  json_inspect(response.output.length(), content=1)
  guard response.output[0] is Message(msg) else {
    fail("Expected Message output item")
  }
  json_inspect(msg.id, content="msg_001")
  guard msg.content[0] is OutputText(text) else {
    fail("Expected OutputText content")
  }
  json_inspect(text.text, content="I can help you!")
}

///|
test "Response::with_optional_fields" {
  let json : Json = {
    "id": "resp_789",
    "created_at": 1234567890.0,
    "error": { "code": "server_error", "message": "" },
    "incomplete_details": { "reason": "max_output_tokens" },
    "instructions": "Help user",
    "metadata": { "key": "value" },
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
    "max_output_tokens": 4096,
    "service_tier": "default",
    "previous_response_id": "resp_prev_123",
  }
  let response : @responses.Response = @json.from_json(json)
  guard response.max_output_tokens is Some(max_tokens) else {
    fail("Expected Some max_output_tokens")
  }
  inspect(max_tokens, content="4096")
  guard response.previous_response_id is Some(prev_id) else {
    fail("Expected Some previous_response_id")
  }
  json_inspect(prev_id, content="resp_prev_123")
}

///|
test "CompactedResponse::round_trip" {
  let json : Json = {
    "id": "compact_123",
    "created_at": 1234567890,
    "object": "response.compact",
    "output": [
      {
        "type": "message",
        "id": "msg_compact",
        "role": "assistant",
        "content": [
          { "type": "output_text", "text": "Compacted!", "annotations": [] },
        ],
        "status": "completed",
      },
    ],
    "usage": {
      "input_tokens": 100,
      "input_tokens_details": { "cached_tokens": 50 },
      "output_tokens": 200,
      "output_tokens_details": { "reasoning_tokens": 25 },
      "total_tokens": 300,
    },
  }
  let response : @responses.CompactedResponse = @json.from_json(json)
  json_inspect(response.id, content="compact_123")
  json_inspect(response.object_, content="response.compact")
  json_inspect(response.output.length(), content=1)
  inspect(response.usage.total_tokens, content="300")
}

///|
test "ResponseServiceTier::auto" {
  let json : Json = "auto"
  let tier : @responses.ResponseServiceTier = @json.from_json(json)
  json_inspect(tier.to_json(), content="auto")
}

///|
test "ResponseServiceTier::default" {
  let json : Json = "default"
  let tier : @responses.ResponseServiceTier = @json.from_json(json)
  json_inspect(tier.to_json(), content="default")
}

///|
test "ResponseServiceTier::flex" {
  let json : Json = "flex"
  let tier : @responses.ResponseServiceTier = @json.from_json(json)
  json_inspect(tier.to_json(), content="flex")
}

///|
test "ResponseServiceTier::scale" {
  let json : Json = "scale"
  let tier : @responses.ResponseServiceTier = @json.from_json(json)
  json_inspect(tier.to_json(), content="scale")
}

///|
test "ResponseServiceTier::priority" {
  let json : Json = "priority"
  let tier : @responses.ResponseServiceTier = @json.from_json(json)
  json_inspect(tier.to_json(), content="priority")
}

///|
test "ResponseServiceTier::invalid" {
  let json : Json = "invalid_tier"
  let result = try {
    let _ : @responses.ResponseServiceTier = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ Additional ResponseToolChoice Variants ============

///|
test "ResponseToolChoice::computer_use_preview" {
  let json : Json = { "type": "computer_use_preview" }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Hosted(hosted) else { fail("Expected Hosted variant") }
  json_inspect(hosted.type_.to_json(), content="computer_use_preview")
}

///|
test "ResponseToolChoice::image_generation" {
  let json : Json = { "type": "image_generation" }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Hosted(hosted) else { fail("Expected Hosted variant") }
  json_inspect(hosted.type_.to_json(), content="image_generation")
}

///|
test "ResponseToolChoice::code_interpreter" {
  let json : Json = { "type": "code_interpreter" }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Hosted(hosted) else { fail("Expected Hosted variant") }
  json_inspect(hosted.type_.to_json(), content="code_interpreter")
}

///|
test "ResponseToolChoice::custom" {
  let json : Json = { "type": "custom", "name": "my_custom_tool" }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Custom(custom) else { fail("Expected Custom variant") }
  json_inspect(custom.name, content="my_custom_tool")
}

///|
test "ResponseToolChoice::apply_patch" {
  let json : Json = { "type": "apply_patch" }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is ApplyPatch(_) else { fail("Expected ApplyPatch variant") }
  json_inspect(choice.to_json(), content={ "type": "apply_patch" })
}

///|
test "ResponseToolChoice::shell" {
  let json : Json = { "type": "shell" }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Shell(_) else { fail("Expected Shell variant") }
  json_inspect(choice.to_json(), content={ "type": "shell" })
}

///|
test "ResponseToolChoice::allowed" {
  let json : Json = {
    "type": "allowed_tools",
    "mode": "auto",
    "tools": ["tool1", "tool2"],
  }
  let choice : @responses.ResponseToolChoice = @json.from_json(json)
  guard choice is Allowed(allowed) else { fail("Expected Allowed variant") }
  json_inspect(allowed.mode.to_json(), content="auto")
}

///|
test "ResponseToolChoice::invalid" {
  let json : Json = { "type": "invalid_tool_choice" }
  let result = try {
    let _ : @responses.ResponseToolChoice = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ Response with Additional Fields ============

///|
test "Response::with_truncation" {
  let json : Json = {
    "id": "resp_trunc",
    "created_at": 1234567890.0,
    "error": { "code": "server_error", "message": "" },
    "incomplete_details": { "reason": "max_output_tokens" },
    "instructions": "Be helpful",
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
    "truncation": "auto",
  }
  let response : @responses.Response = @json.from_json(json)
  guard response.truncation is Some(trunc) else {
    fail("Expected Some truncation")
  }
  json_inspect(trunc.to_json(), content="auto")
}

///|
test "Response::with_reasoning" {
  let json : Json = {
    "id": "resp_reason",
    "created_at": 1234567890.0,
    "error": { "code": "server_error", "message": "" },
    "incomplete_details": { "reason": "max_output_tokens" },
    "instructions": "Think carefully",
    "metadata": {},
    "model": "gpt-4o",
    "object": "response",
    "output": [
      {
        "type": "reasoning",
        "id": "reason_001",
        "summary": [{ "type": "summary_text", "text": "Thinking..." }],
      },
    ],
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
      "output_tokens_details": { "reasoning_tokens": 5 },
      "total_tokens": 30,
    },
  }
  let response : @responses.Response = @json.from_json(json)
  json_inspect(response.output.length(), content=1)
  guard response.output[0] is Reasoning(_) else {
    fail("Expected Reasoning output item")
  }
}
