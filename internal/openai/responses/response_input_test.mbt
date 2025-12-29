///|
/// Tests for input types

///|
test "EasyInputMessageRole::user" {
  let json : Json = "user"
  let role : @responses.EasyInputMessageRole = @json.from_json(json)
  json_inspect(role.to_json(), content="user")
}

///|
test "EasyInputMessageRole::assistant" {
  let json : Json = "assistant"
  let role : @responses.EasyInputMessageRole = @json.from_json(json)
  json_inspect(role.to_json(), content="assistant")
}

///|
test "EasyInputMessageRole::system" {
  let json : Json = "system"
  let role : @responses.EasyInputMessageRole = @json.from_json(json)
  json_inspect(role.to_json(), content="system")
}

///|
test "EasyInputMessageRole::developer" {
  let json : Json = "developer"
  let role : @responses.EasyInputMessageRole = @json.from_json(json)
  json_inspect(role.to_json(), content="developer")
}

///|
test "EasyInputMessageRole::invalid" {
  let json : Json = "invalid_role"
  let result = try {
    let _ : @responses.EasyInputMessageRole = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

///|
test "ResponseInputItemMessageParamRole::user" {
  let json : Json = "user"
  let role : @responses.ResponseInputItemMessageParamRole = @json.from_json(
    json,
  )
  json_inspect(role.to_json(), content="user")
}

///|
test "ResponseInputItemMessageParamRole::system" {
  let json : Json = "system"
  let role : @responses.ResponseInputItemMessageParamRole = @json.from_json(
    json,
  )
  json_inspect(role.to_json(), content="system")
}

///|
test "ResponseInputItemMessageParamRole::developer" {
  let json : Json = "developer"
  let role : @responses.ResponseInputItemMessageParamRole = @json.from_json(
    json,
  )
  json_inspect(role.to_json(), content="developer")
}

///|
test "EasyInputMessageContentParam::string" {
  let json : Json = "Hello, world!"
  let content : @responses.EasyInputMessageContentParam = @json.from_json(json)
  guard content is String(s) else { fail("Expected String variant") }
  json_inspect(s, content="Hello, world!")
  json_inspect(content.to_json(), content="Hello, world!")
}

///|
test "EasyInputMessageContentParam::content_list" {
  let json : Json = [{ "type": "text", "text": "Hello" }]
  let content : @responses.EasyInputMessageContentParam = @json.from_json(json)
  guard content is InputItemContentList(_) else {
    fail("Expected InputItemContentList variant")
  }
}

///|
test "EasyInputMessageParam::string_content" {
  let json : Json = { "role": "user", "content": "Hello!" }
  let message : @responses.EasyInputMessageParam = @json.from_json(json)
  let output_json = message.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["role"], content="user")
  json_inspect(obj["content"], content="Hello!")
}

///|
test "EasyInputMessageParam::array_content" {
  let json : Json = {
    "role": "assistant",
    "content": [{ "type": "text", "text": "Response" }],
  }
  let message : @responses.EasyInputMessageParam = @json.from_json(json)
  let output_json = message.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["role"], content="assistant")
}

///|
test "ResponseInputItemMessageParam::basic" {
  let json : Json = {
    "role": "user",
    "content": [{ "type": "text", "text": "Hello" }],
  }
  let message : @responses.ResponseInputItemMessageParam = @json.from_json(json)
  let output_json = message.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["role"], content="user")
}

///|
test "ResponseInputItemMessageParam::with_status" {
  let json : Json = {
    "role": "system",
    "content": [{ "type": "text", "text": "You are helpful" }],
    "status": "completed",
  }
  let message : @responses.ResponseInputItemMessageParam = @json.from_json(json)
  let output_json = message.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj.get("status") is Some(_), content=true)
}

///|
test "ResponseInputContentParam::InputText" {
  let json : Json = { "type": "text", "text": "Hello world" }
  let content : @responses.ResponseInputContentParam = @json.from_json(json)
  // Verify round-trip by checking to_json output
  let output_json = content.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["text"], content="Hello world")
  json_inspect(obj["type"], content="text")
}

///|
test "ResponseInputContentParam::invalid_type" {
  let json : Json = { "type": "invalid_content_type" }
  let result = try {
    let _ : @responses.ResponseInputContentParam = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

///|
test "ResponseInputItemParam::message_builder" {
  // Test the builder function for creating a message
  let param = @responses.ResponseInputItemParam::message(
    role=@responses.EasyInputMessageRole::User,
    content="Hello!",
  )
  let json = param.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["role"], content="user")
  json_inspect(obj["content"], content="Hello!")
}

///|
test "ResponseInputFile::with_file_id" {
  let json : Json = { "type": "file", "file_id": "file_abc123" }
  let file : @responses.ResponseInputFile = @json.from_json(json)
  let output_json = file.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="file")
  json_inspect(obj["file_id"], content="file_abc123")
}

///|
test "ResponseInputFile::with_file_url" {
  let json : Json = {
    "type": "file",
    "file_url": "https://example.com/document.pdf",
    "filename": "document.pdf",
  }
  let file : @responses.ResponseInputFile = @json.from_json(json)
  let output_json = file.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="file")
  json_inspect(obj["file_url"], content="https://example.com/document.pdf")
  json_inspect(obj["filename"], content="document.pdf")
}

///|
test "ResponseInputFile::with_file_data" {
  let json : Json = {
    "type": "file",
    "file_data": "base64_encoded_data",
    "filename": "data.txt",
  }
  let file : @responses.ResponseInputFile = @json.from_json(json)
  let output_json = file.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["file_data"], content="base64_encoded_data")
}

///|
test "ResponseInputImage::with_file_id" {
  let json : Json = {
    "type": "image",
    "detail": "high",
    "file_id": "img_abc123",
  }
  let image : @responses.ResponseInputImage = @json.from_json(json)
  let output_json = image.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="image")
  json_inspect(obj["detail"], content="high")
  json_inspect(obj["file_id"], content="img_abc123")
}

///|
test "ResponseInputImage::with_image_url" {
  let json : Json = {
    "type": "image",
    "detail": "low",
    "image_url": "https://example.com/photo.jpg",
  }
  let image : @responses.ResponseInputImage = @json.from_json(json)
  let output_json = image.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["image_url"], content="https://example.com/photo.jpg")
  json_inspect(obj["detail"], content="low")
}

///|
test "ResponseInputImageDetail::all_values" {
  let low_json : Json = "low"
  let low : @responses.ResponseInputImageDetail = @json.from_json(low_json)
  json_inspect(low.to_json(), content="low")
  let high_json : Json = "high"
  let high : @responses.ResponseInputImageDetail = @json.from_json(high_json)
  json_inspect(high.to_json(), content="high")
  let auto_json : Json = "auto"
  let auto : @responses.ResponseInputImageDetail = @json.from_json(auto_json)
  json_inspect(auto.to_json(), content="auto")
}

///|
test "ResponseInputImageDetail::invalid" {
  let json : Json = "invalid_detail"
  let result = try {
    let _ : @responses.ResponseInputImageDetail = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

///|
test "ResponseInputItemMessageParamStatus::in_progress" {
  let json : Json = "in_progress"
  let status : @responses.ResponseInputItemMessageParamStatus = @json.from_json(
    json,
  )
  json_inspect(status.to_json(), content="in_progress")
}

///|
test "ResponseInputItemMessageParamStatus::completed" {
  let json : Json = "completed"
  let status : @responses.ResponseInputItemMessageParamStatus = @json.from_json(
    json,
  )
  json_inspect(status.to_json(), content="completed")
}

///|
test "ResponseInputItemMessageParamStatus::incomplete" {
  let json : Json = "incomplete"
  let status : @responses.ResponseInputItemMessageParamStatus = @json.from_json(
    json,
  )
  json_inspect(status.to_json(), content="incomplete")
}

///|
test "ResponseInputItemMessageParamStatus::invalid" {
  let json : Json = "invalid_status"
  let result = try {
    let _ : @responses.ResponseInputItemMessageParamStatus = @json.from_json(
      json,
    )
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

// ============ ResponseInputItemParam Variants ============

///|
test "ResponseInputItemParam::FunctionCall_to_json" {
  // Use the builder function to create a FunctionCall
  let param = @responses.ResponseInputItemParam::message(
    role=@responses.EasyInputMessageRole::User,
    content="Hello",
  )
  // First verify the Message variant works
  let json = param.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["role"], content="user")
}

///|
test "ResponseInputItemParam::message_with_array_content" {
  // Test using an array of content items
  let param = @responses.ResponseInputItemParam::message(
    role=@responses.EasyInputMessageRole::Assistant,
    content="Hello from assistant",
  )
  let json = param.to_json()
  guard json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["role"], content="assistant")
}

///|
test "ResponseInputImage::detail_auto" {
  let json : Json = {
    "type": "image",
    "detail": "auto",
    "image_url": "https://example.com/image.png",
  }
  let image : @responses.ResponseInputImage = @json.from_json(json)
  let output_json = image.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["detail"], content="auto")
}

///|
test "ResponseInputImage::with_both_file_id_and_url" {
  let json : Json = {
    "type": "image",
    "detail": "low",
    "file_id": "file_123",
    "image_url": "https://example.com/photo.png",
  }
  let image : @responses.ResponseInputImage = @json.from_json(json)
  let output_json = image.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["detail"], content="low")
  json_inspect(obj.get("file_id") is Some(_), content=true)
  json_inspect(obj.get("image_url") is Some(_), content=true)
}

// ============ EasyInputMessageParam Additional Tests ============

///|
test "EasyInputMessageParam::with_type_field" {
  let json : Json = { "role": "user", "content": "Hello!", "type": "message" }
  let message : @responses.EasyInputMessageParam = @json.from_json(json)
  let output_json = message.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["role"], content="user")
}

///|
test "EasyInputMessageParam::developer_role" {
  let json : Json = {
    "role": "developer",
    "content": "System configuration message",
  }
  let message : @responses.EasyInputMessageParam = @json.from_json(json)
  let output_json = message.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["role"], content="developer")
}

///|
test "EasyInputMessageParam::system_role" {
  let json : Json = {
    "role": "system",
    "content": "You are a helpful assistant.",
  }
  let message : @responses.EasyInputMessageParam = @json.from_json(json)
  let output_json = message.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["role"], content="system")
}
