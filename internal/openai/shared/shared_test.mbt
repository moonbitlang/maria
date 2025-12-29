///|
/// Tests for shared types

///|
test "ComparisonFilterType::eq" {
  let json : Json = "eq"
  let filter_type : @shared.ComparisonFilterType = @json.from_json(json)
  json_inspect(filter_type.to_json(), content="eq")
}

///|
test "ComparisonFilterType::ne" {
  let json : Json = "ne"
  let filter_type : @shared.ComparisonFilterType = @json.from_json(json)
  json_inspect(filter_type.to_json(), content="ne")
}

///|
test "ComparisonFilterType::gt" {
  let json : Json = "gt"
  let filter_type : @shared.ComparisonFilterType = @json.from_json(json)
  json_inspect(filter_type.to_json(), content="gt")
}

///|
test "ComparisonFilterType::gte" {
  let json : Json = "gte"
  let filter_type : @shared.ComparisonFilterType = @json.from_json(json)
  json_inspect(filter_type.to_json(), content="gte")
}

///|
test "ComparisonFilterType::lt" {
  let json : Json = "lt"
  let filter_type : @shared.ComparisonFilterType = @json.from_json(json)
  json_inspect(filter_type.to_json(), content="lt")
}

///|
test "ComparisonFilterType::lte" {
  let json : Json = "lte"
  let filter_type : @shared.ComparisonFilterType = @json.from_json(json)
  json_inspect(filter_type.to_json(), content="lte")
}

///|
test "ComparisonFilterType::invalid" {
  let json : Json = "invalid_type"
  let result = try {
    let _ : @shared.ComparisonFilterType = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

///|
test "ComparisonFilter::string_value" {
  let json : Json = { "key": "status", "type": "eq", "value": "active" }
  let filter : @shared.ComparisonFilter = @json.from_json(json)
  let output_json = filter.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["key"], content="status")
  json_inspect(obj["type"], content="eq")
  json_inspect(obj["value"], content="active")
}

///|
test "ComparisonFilter::numeric_value" {
  let json : Json = { "key": "count", "type": "gt", "value": 100 }
  let filter : @shared.ComparisonFilter = @json.from_json(json)
  let output_json = filter.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["key"], content="count")
  json_inspect(obj["type"], content="gt")
}

///|
test "ComparisonFilter::bool_value" {
  let json : Json = { "key": "enabled", "type": "eq", "value": true }
  let filter : @shared.ComparisonFilter = @json.from_json(json)
  let output_json = filter.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["value"], content=true)
}

///|
test "CompoundFilterType::and" {
  let json : Json = "and"
  let filter_type : @shared.CompoundFilterType = @json.from_json(json)
  json_inspect(filter_type.to_json(), content="and")
}

///|
test "CompoundFilterType::or" {
  let json : Json = "or"
  let filter_type : @shared.CompoundFilterType = @json.from_json(json)
  json_inspect(filter_type.to_json(), content="or")
}

///|
test "CompoundFilterType::invalid" {
  let json : Json = "xor"
  let result = try {
    let _ : @shared.CompoundFilterType = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

///|
test "CompoundFilter::with_filters" {
  let json : Json = {
    "type": "and",
    "filters": [
      { "key": "status", "type": "eq", "value": "active" },
      { "key": "count", "type": "gte", "value": 10 },
    ],
  }
  let filter : @shared.CompoundFilter = @json.from_json(json)
  let output_json = filter.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="and")
  guard obj["filters"] is Array(filters) else { fail("Expected Array") }
  json_inspect(filters.length(), content=2)
}

///|
test "FunctionDefinition::full" {
  let json : Json = {
    "name": "get_weather",
    "description": "Get the current weather",
    "parameters": {
      "type": "object",
      "properties": { "location": { "type": "string" } },
    },
    "strict": true,
  }
  let func : @shared.FunctionDefinition = @json.from_json(json)
  let output_json = func.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["name"], content="get_weather")
  json_inspect(obj["description"], content="Get the current weather")
  json_inspect(obj.get("strict") is Some(True), content=true)
}

///|
test "FunctionDefinition::minimal" {
  let json : Json = { "name": "simple_func" }
  let func : @shared.FunctionDefinition = @json.from_json(json)
  let output_json = func.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["name"], content="simple_func")
}

///|
test "CustomToolInputFormatUnion::Text" {
  let json : Json = { "type": "text" }
  let format : @shared.CustomToolInputFormatUnion = @json.from_json(json)
  let output_json = format.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="text")
}

///|
test "CustomToolInputFormatUnion::Grammar" {
  let json : Json = {
    "type": "grammar",
    "definition": "rule = \"a\" | \"b\"",
    "syntax": "bnf",
  }
  let format : @shared.CustomToolInputFormatUnion = @json.from_json(json)
  let output_json = format.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="grammar")
  json_inspect(obj["syntax"], content="bnf")
}

///|
test "CustomToolInputFormatUnion::invalid_type" {
  let json : Json = { "type": "invalid" }
  let result = try {
    let _ : @shared.CustomToolInputFormatUnion = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

///|
test "ResponseFormat::Text_to_json" {
  let format = @shared.ResponseFormat::Text
  let json = format.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="text")
}

///|
test "ResponseFormat::JsonObject_to_json" {
  let format = @shared.ResponseFormat::JsonObject
  let json = format.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="json_object")
}

// ============ ReasoningEffort ============

///|
test "ReasoningEffort::none" {
  let json : Json = "none"
  let effort : @shared.ReasoningEffort = @json.from_json(json)
  json_inspect(effort.to_json(), content="none")
}

///|
test "ReasoningEffort::minimal" {
  let json : Json = "minimal"
  let effort : @shared.ReasoningEffort = @json.from_json(json)
  json_inspect(effort.to_json(), content="minimal")
}

///|
test "ReasoningEffort::low" {
  let json : Json = "low"
  let effort : @shared.ReasoningEffort = @json.from_json(json)
  json_inspect(effort.to_json(), content="low")
}

///|
test "ReasoningEffort::medium" {
  let json : Json = "medium"
  let effort : @shared.ReasoningEffort = @json.from_json(json)
  json_inspect(effort.to_json(), content="medium")
}

///|
test "ReasoningEffort::high" {
  let json : Json = "high"
  let effort : @shared.ReasoningEffort = @json.from_json(json)
  json_inspect(effort.to_json(), content="high")
}

///|
test "ReasoningEffort::xhigh" {
  let json : Json = "xhigh"
  let effort : @shared.ReasoningEffort = @json.from_json(json)
  json_inspect(effort.to_json(), content="xhigh")
}

///|
test "ReasoningEffort::invalid" {
  let json : Json = "invalid_effort"
  let result = try {
    let _ : @shared.ReasoningEffort = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ ReasoningGenerateSummary ============

///|
test "ReasoningGenerateSummary::auto" {
  let json : Json = "auto"
  let summary : @shared.ReasoningGenerateSummary = @json.from_json(json)
  json_inspect(summary.to_json(), content="auto")
}

///|
test "ReasoningGenerateSummary::concise" {
  let json : Json = "concise"
  let summary : @shared.ReasoningGenerateSummary = @json.from_json(json)
  json_inspect(summary.to_json(), content="concise")
}

///|
test "ReasoningGenerateSummary::detailed" {
  let json : Json = "detailed"
  let summary : @shared.ReasoningGenerateSummary = @json.from_json(json)
  json_inspect(summary.to_json(), content="detailed")
}

///|
test "ReasoningGenerateSummary::invalid" {
  let json : Json = "invalid_summary"
  let result = try {
    let _ : @shared.ReasoningGenerateSummary = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ ReasoningSummary ============

///|
test "ReasoningSummary::auto" {
  let json : Json = "auto"
  let summary : @shared.ReasoningSummary = @json.from_json(json)
  json_inspect(summary.to_json(), content="auto")
}

///|
test "ReasoningSummary::concise" {
  let json : Json = "concise"
  let summary : @shared.ReasoningSummary = @json.from_json(json)
  json_inspect(summary.to_json(), content="concise")
}

///|
test "ReasoningSummary::detailed" {
  let json : Json = "detailed"
  let summary : @shared.ReasoningSummary = @json.from_json(json)
  json_inspect(summary.to_json(), content="detailed")
}

///|
test "ReasoningSummary::invalid" {
  let json : Json = "invalid_summary"
  let result = try {
    let _ : @shared.ReasoningSummary = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ Reasoning ============

///|
test "Reasoning::empty" {
  let json : Json = {}
  let reasoning : @shared.Reasoning = @json.from_json(json)
  let output_json = reasoning.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj.get("effort") is None, content=true)
  json_inspect(obj.get("generate_summary") is None, content=true)
  json_inspect(obj.get("summary") is None, content=true)
}

///|
test "Reasoning::with_effort" {
  let json : Json = { "effort": "high" }
  let reasoning : @shared.Reasoning = @json.from_json(json)
  let output_json = reasoning.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["effort"], content="high")
}

///|
test "Reasoning::with_summary" {
  let json : Json = { "summary": "concise" }
  let reasoning : @shared.Reasoning = @json.from_json(json)
  let output_json = reasoning.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["summary"], content="concise")
}

///|
test "Reasoning::with_generate_summary" {
  let json : Json = { "generate_summary": "detailed" }
  let reasoning : @shared.Reasoning = @json.from_json(json)
  let output_json = reasoning.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["generate_summary"], content="detailed")
}

///|
test "Reasoning::full" {
  let json : Json = {
    "effort": "medium",
    "generate_summary": "auto",
    "summary": "detailed",
  }
  let reasoning : @shared.Reasoning = @json.from_json(json)
  let output_json = reasoning.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["effort"], content="medium")
  json_inspect(obj["generate_summary"], content="auto")
  json_inspect(obj["summary"], content="detailed")
}

// ============ ErrorObject ============

///|
test "ErrorObject::round_trip" {
  let json : Json = {
    "code": "rate_limit_exceeded",
    "message": "You have exceeded your rate limit",
    "param": "messages",
    "type": "invalid_request_error",
  }
  let error : @shared.ErrorObject = @json.from_json(json)
  let output_json = error.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["code"], content="rate_limit_exceeded")
  json_inspect(obj["message"], content="You have exceeded your rate limit")
  json_inspect(obj["param"], content="messages")
  json_inspect(obj["type"], content="invalid_request_error")
}

///|
test "ErrorObject::server_error" {
  let json : Json = {
    "code": "server_error",
    "message": "Internal server error occurred",
    "param": "",
    "type": "server_error",
  }
  let error : @shared.ErrorObject = @json.from_json(json)
  json_inspect(error.to_json(), content=json)
}

// ============ Metadata ============

///|
test "Metadata::empty" {
  let json : Json = {}
  let metadata : @shared.Metadata = @json.from_json(json)
  let output_json = metadata.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj.length(), content=0)
}

///|
test "Metadata::with_values" {
  let json : Json = { "key1": "value1", "key2": "value2" }
  let metadata : @shared.Metadata = @json.from_json(json)
  let output_json = metadata.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["key1"], content="value1")
  json_inspect(obj["key2"], content="value2")
}

///|
test "Metadata::invalid_value" {
  let json : Json = { "key": 123 }
  let result = try {
    let _ : @shared.Metadata = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}
