///|
/// Tests for additional response types

// ============ ResponseConversation ============

///|
test "ResponseConversation::round_trip" {
  let json : Json = { "id": "conv_123abc" }
  let conv : @responses.ResponseConversation = @json.from_json(json)
  json_inspect(conv.id, content="conv_123abc")
  json_inspect(conv.to_json(), content=json)
}

// ============ ResponseTruncation ============

///|
test "ResponseTruncation::auto" {
  let json : Json = "auto"
  let truncation : @responses.ResponseTruncation = @json.from_json(json)
  json_inspect(truncation.to_json(), content="auto")
}

///|
test "ResponseTruncation::disabled" {
  let json : Json = "disabled"
  let truncation : @responses.ResponseTruncation = @json.from_json(json)
  json_inspect(truncation.to_json(), content="disabled")
}

///|
test "ResponseTruncation::invalid" {
  let json : Json = "invalid_truncation"
  let result = try {
    let _ : @responses.ResponseTruncation = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ ResponseReasoningItemStatus ============

///|
test "ResponseReasoningItemStatus::in_progress" {
  let json : Json = "in_progress"
  let status : @responses.ResponseReasoningItemStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="in_progress")
}

///|
test "ResponseReasoningItemStatus::completed" {
  let json : Json = "completed"
  let status : @responses.ResponseReasoningItemStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="completed")
}

///|
test "ResponseReasoningItemStatus::incomplete" {
  let json : Json = "incomplete"
  let status : @responses.ResponseReasoningItemStatus = @json.from_json(json)
  json_inspect(status.to_json(), content="incomplete")
}

///|
test "ResponseReasoningItemStatus::invalid" {
  let json : Json = "invalid_status"
  let result = try {
    let _ : @responses.ResponseReasoningItemStatus = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ ResponseReasoningItemSummary ============

///|
test "ResponseReasoningItemSummary::round_trip" {
  let json : Json = { "type": "summary_text", "text": "This is a summary" }
  let summary : @responses.ResponseReasoningItemSummary = @json.from_json(json)
  json_inspect(summary.to_json(), content=json)
}

// ============ ResponseReasoningItemContent ============

///|
test "ResponseReasoningItemContent::round_trip" {
  let json : Json = { "type": "reasoning_text", "text": "Let me think..." }
  let content : @responses.ResponseReasoningItemContent = @json.from_json(json)
  json_inspect(content.to_json(), content=json)
}

// ============ ResponseReasoningItem ============

///|
test "ResponseReasoningItem::minimal" {
  let json : Json = {
    "type": "reasoning",
    "id": "reason_001",
    "summary": [{ "type": "summary_text", "text": "Summary here" }],
  }
  let item : @responses.ResponseReasoningItem = @json.from_json(json)
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="reason_001")
  json_inspect(obj["type"], content="reasoning")
}

///|
test "ResponseReasoningItem::with_content" {
  let json : Json = {
    "type": "reasoning",
    "id": "reason_002",
    "summary": [{ "type": "summary_text", "text": "Brief summary" }],
    "content": [{ "type": "reasoning_text", "text": "Detailed reasoning here" }],
  }
  let item : @responses.ResponseReasoningItem = @json.from_json(json)
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj.get("content") is Some(_), content=true)
}

///|
test "ResponseReasoningItem::with_encrypted_content" {
  let json : Json = {
    "type": "reasoning",
    "id": "reason_003",
    "summary": [{ "type": "summary_text", "text": "Encrypted" }],
    "encrypted_content": "base64_encrypted_data_here",
  }
  let item : @responses.ResponseReasoningItem = @json.from_json(json)
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["encrypted_content"], content="base64_encrypted_data_here")
}

///|
test "ResponseReasoningItem::with_status" {
  let json : Json = {
    "type": "reasoning",
    "id": "reason_004",
    "summary": [{ "type": "summary_text", "text": "Done" }],
    "status": "completed",
  }
  let item : @responses.ResponseReasoningItem = @json.from_json(json)
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["status"], content="completed")
}

///|
test "ResponseReasoningItem::full" {
  let json : Json = {
    "type": "reasoning",
    "id": "reason_005",
    "summary": [
      { "type": "summary_text", "text": "Part 1" },
      { "type": "summary_text", "text": "Part 2" },
    ],
    "content": [
      { "type": "reasoning_text", "text": "First thought" },
      { "type": "reasoning_text", "text": "Second thought" },
    ],
    "encrypted_content": "encrypted_blob",
    "status": "in_progress",
  }
  let item : @responses.ResponseReasoningItem = @json.from_json(json)
  let output_json = item.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="reason_005")
  json_inspect(obj.get("status") is Some(_), content=true)
  json_inspect(obj.get("content") is Some(_), content=true)
  json_inspect(obj.get("encrypted_content") is Some(_), content=true)
}

// ============ ResponsePromptVariable ============

///|
test "ResponsePromptVariable::text" {
  let json : Json = "simple text value"
  let variable : @responses.ResponsePromptVariable = @json.from_json(json)
  guard variable is Text(text) else { fail("Expected Text variant") }
  json_inspect(text, content="simple text value")
  json_inspect(variable.to_json(), content="simple text value")
}

///|
test "ResponsePromptVariable::input_text" {
  let json : Json = { "type": "input_text", "text": "Hello from input" }
  let variable : @responses.ResponsePromptVariable = @json.from_json(json)
  guard variable is InputText(_) else { fail("Expected InputText variant") }
  let output_json = variable.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["text"], content="Hello from input")
}

///|
test "ResponsePromptVariable::input_image" {
  let json : Json = {
    "type": "input_image",
    "detail": "high",
    "image_url": "https://example.com/image.jpg",
  }
  let variable : @responses.ResponsePromptVariable = @json.from_json(json)
  guard variable is InputImage(_) else { fail("Expected InputImage variant") }
}

///|
test "ResponsePromptVariable::input_file" {
  let json : Json = { "type": "input_file", "file_id": "file_abc123" }
  let variable : @responses.ResponsePromptVariable = @json.from_json(json)
  guard variable is InputFile(_) else { fail("Expected InputFile variant") }
}

///|
test "ResponsePromptVariable::invalid" {
  let json : Json = { "type": "invalid_type" }
  let result = try {
    let _ : @responses.ResponsePromptVariable = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ ResponsePrompt ============

///|
test "ResponsePrompt::minimal" {
  let json : Json = { "id": "prompt_123" }
  let prompt : @responses.ResponsePrompt = @json.from_json(json)
  json_inspect(prompt.id, content="prompt_123")
  json_inspect(prompt.variables is None, content=true)
  json_inspect(prompt.version is None, content=true)
  let output_json = prompt.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["id"], content="prompt_123")
}

///|
test "ResponsePrompt::with_version" {
  let json : Json = { "id": "prompt_456", "version": "v1.2.3" }
  let prompt : @responses.ResponsePrompt = @json.from_json(json)
  guard prompt.version is Some(version) else { fail("Expected Some version") }
  json_inspect(version, content="v1.2.3")
}

///|
test "ResponsePrompt::with_variables" {
  let json : Json = {
    "id": "prompt_789",
    "variables": { "name": "John", "greeting": "Hello" },
  }
  let prompt : @responses.ResponsePrompt = @json.from_json(json)
  guard prompt.variables is Some(vars) else { fail("Expected Some variables") }
  json_inspect(vars.length(), content=2)
}

///|
test "ResponsePrompt::full" {
  let json : Json = {
    "id": "prompt_full",
    "version": "2.0.0",
    "variables": { "text_var": "plain text" },
  }
  let prompt : @responses.ResponsePrompt = @json.from_json(json)
  json_inspect(prompt.id, content="prompt_full")
  json_inspect(prompt.version is Some(_), content=true)
  json_inspect(prompt.variables is Some(_), content=true)
  let output_json = prompt.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj.get("version") is Some(_), content=true)
  json_inspect(obj.get("variables") is Some(_), content=true)
}

// ============ ResponseOutputRefusal ============

///|
test "ResponseOutputRefusal::round_trip" {
  let json : Json = { "type": "refusal", "refusal": "I cannot help with that" }
  let refusal : @responses.ResponseOutputRefusal = @json.from_json(json)
  let output_json = refusal.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="refusal")
  json_inspect(obj["refusal"], content="I cannot help with that")
}

// ============ ResponseInputText ============

///|
test "ResponseInputText::round_trip" {
  let json : Json = { "type": "input_text", "text": "User input here" }
  let input : @responses.ResponseInputText = @json.from_json(json)
  json_inspect(input.to_json(), content={
    "text": "User input here",
    "type": "input_text",
  })
}
