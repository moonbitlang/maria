///|
/// Tests for ResponseService parameter types

///|
test "ResponseGetParams::empty" {
  let params = @responses.ResponseGetParams::empty()
  json_inspect(params.include_obfuscation is None, content=true)
  json_inspect(params.starting_after is None, content=true)
  json_inspect(params.include_items.length(), content=0)
}

///|
test "ResponseCompactParams::new_minimal" {
  let params = @responses.ResponseCompactParams::new(model="gpt-4o")
  let json = params.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["model"], content="gpt-4o")
  json_inspect(obj.get("input") is None, content=true)
  json_inspect(obj.get("instructions") is None, content=true)
  json_inspect(obj.get("previous_response_id") is None, content=true)
}

///|
test "ResponseCompactParams::new_with_instructions" {
  let params = @responses.ResponseCompactParams::new(
    model="gpt-4o-mini",
    instructions="Be helpful",
  )
  let json = params.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["model"], content="gpt-4o-mini")
  json_inspect(obj["instructions"], content="Be helpful")
}

///|
test "ResponseCompactParams::new_with_previous_response_id" {
  let params = @responses.ResponseCompactParams::new(
    model="gpt-4o",
    previous_response_id="resp_123",
  )
  let json = params.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["previous_response_id"], content="resp_123")
}

///|
test "ResponseCompactParams::new_with_input" {
  let input = [
    @responses.ResponseInputItemParam::message(
      role=@responses.EasyInputMessageRole::User,
      content="Hello!",
    ),
  ]
  let params = @responses.ResponseCompactParams::new(model="gpt-4o", input~)
  let json = params.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj.get("input") is Some(_), content=true)
}

///|
test "CompactedResponse::from_json" {
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
}

///|
test "ResponseService::new" {
  let service = @responses.ResponseService::new(
    base_url="https://api.openai.com/v1",
    api_key="sk-test-key",
  )
  json_inspect(service.base_url, content="https://api.openai.com/v1")
  json_inspect(service.api_key, content="sk-test-key")
}

///|
test "ResponseGetParams::empty_defaults" {
  let params = @responses.ResponseGetParams::empty()
  json_inspect(params.include_obfuscation is None, content=true)
  json_inspect(params.starting_after is None, content=true)
  json_inspect(params.include_items.is_empty(), content=true)
}

///|
test "ResponseCompactParams::new_full" {
  let input = [
    @responses.ResponseInputItemParam::message(
      role=@responses.EasyInputMessageRole::User,
      content="What is the weather?",
    ),
    @responses.ResponseInputItemParam::message(
      role=@responses.EasyInputMessageRole::Assistant,
      content="Let me check that for you.",
    ),
  ]
  let params = @responses.ResponseCompactParams::new(
    model="gpt-4o",
    input~,
    instructions="Be concise",
    previous_response_id="resp_previous_123",
  )
  let json = params.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["model"], content="gpt-4o")
  json_inspect(obj["instructions"], content="Be concise")
  json_inspect(obj["previous_response_id"], content="resp_previous_123")
  json_inspect(obj.get("input") is Some(_), content=true)
}

///|
test "CompactedResponse::from_json_with_multiple_outputs" {
  let json : Json = {
    "id": "compact_multi",
    "created_at": 1234567890,
    "object": "response.compact",
    "output": [
      {
        "type": "reasoning",
        "id": "reason_001",
        "summary": [{ "type": "summary_text", "text": "Thinking..." }],
      },
      {
        "type": "message",
        "id": "msg_001",
        "role": "assistant",
        "content": [
          {
            "type": "output_text",
            "text": "Here is the answer.",
            "annotations": [],
          },
        ],
        "status": "completed",
      },
    ],
    "usage": {
      "input_tokens": 200,
      "input_tokens_details": { "cached_tokens": 100 },
      "output_tokens": 300,
      "output_tokens_details": { "reasoning_tokens": 50 },
      "total_tokens": 500,
    },
  }
  let response : @responses.CompactedResponse = @json.from_json(json)
  json_inspect(response.id, content="compact_multi")
  json_inspect(response.output.length(), content=2)
}
