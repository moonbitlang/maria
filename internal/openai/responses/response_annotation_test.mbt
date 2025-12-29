///|
/// Tests for ResponseOutputTextAnnotation variants

///|
test "ResponseOutputTextAnnotation::FileCitation" {
  let json : Json = {
    "type": "file_citation",
    "file_id": "file_001",
    "filename": "document.pdf",
    "index": 5,
  }
  let annotation : @responses.ResponseOutputTextAnnotation = @json.from_json(
    json,
  )
  let output_json = annotation.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="file_citation")
  json_inspect(obj["file_id"], content="file_001")
  json_inspect(obj["filename"], content="document.pdf")
}

///|
test "ResponseOutputTextAnnotation::UrlCitation" {
  let json : Json = {
    "type": "url_citation",
    "start_index": 10,
    "end_index": 50,
    "title": "Example Web Page",
    "url": "https://example.com/page",
  }
  let annotation : @responses.ResponseOutputTextAnnotation = @json.from_json(
    json,
  )
  let output_json = annotation.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="url_citation")
  json_inspect(obj["title"], content="Example Web Page")
  json_inspect(obj["url"], content="https://example.com/page")
}

///|
test "ResponseOutputTextAnnotation::ContainerFileCitation" {
  let json : Json = {
    "type": "container_file_citation",
    "container_id": "container_001",
    "file_id": "file_002",
    "start_index": 0,
    "end_index": 100,
  }
  let annotation : @responses.ResponseOutputTextAnnotation = @json.from_json(
    json,
  )
  let output_json = annotation.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="container_file_citation")
  json_inspect(obj["container_id"], content="container_001")
  json_inspect(obj["file_id"], content="file_002")
}

///|
test "ResponseOutputTextAnnotation::FilePath" {
  let json : Json = { "type": "file_path", "file_id": "file_003", "index": 3 }
  let annotation : @responses.ResponseOutputTextAnnotation = @json.from_json(
    json,
  )
  let output_json = annotation.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["type"], content="file_path")
  json_inspect(obj["file_id"], content="file_003")
}

///|
test "ResponseOutputTextAnnotation::invalid_type" {
  let json : Json = { "type": "invalid_annotation_type" }
  let result = try {
    let _ : @responses.ResponseOutputTextAnnotation = @json.from_json(json)
    false
  } catch {
    @json.JsonDecodeError(_) => true
  }
  json_inspect(result, content=true)
}

///|
test "ResponseOutputTextAnnotationFileCitationParam::round_trip" {
  let json : Json = {
    "type": "file_citation",
    "file_id": "file_roundtrip",
    "filename": "test.txt",
    "index": 42,
  }
  let annotation : @responses.ResponseOutputTextAnnotationFileCitationParam = @json.from_json(
    json,
  )
  let output_json = annotation.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["file_id"], content="file_roundtrip")
  json_inspect(obj["filename"], content="test.txt")
}

///|
test "ResponseOutputTextAnnotationUrlCitationParam::round_trip" {
  let json : Json = {
    "type": "url_citation",
    "start_index": 100,
    "end_index": 200,
    "title": "Test Article",
    "url": "https://test.com",
  }
  let annotation : @responses.ResponseOutputTextAnnotationUrlCitationParam = @json.from_json(
    json,
  )
  let output_json = annotation.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["title"], content="Test Article")
  json_inspect(obj["url"], content="https://test.com")
}

///|
test "ResponseOutputTextAnnotationContainerFileCitationParam::round_trip" {
  let json : Json = {
    "type": "container_file_citation",
    "container_id": "cont_test",
    "file_id": "file_test",
    "start_index": 25,
    "end_index": 75,
  }
  let annotation : @responses.ResponseOutputTextAnnotationContainerFileCitationParam = @json.from_json(
    json,
  )
  let output_json = annotation.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["container_id"], content="cont_test")
  json_inspect(obj["file_id"], content="file_test")
}

///|
test "ResponseOutputTextAnnotationFilePathParam::round_trip" {
  let json : Json = {
    "type": "file_path",
    "file_id": "file_path_test",
    "index": 99,
  }
  let annotation : @responses.ResponseOutputTextAnnotationFilePathParam = @json.from_json(
    json,
  )
  let output_json = annotation.to_json()
  guard output_json is Object(obj) else { fail("Expected Object") }
  json_inspect(obj["file_id"], content="file_path_test")
}
