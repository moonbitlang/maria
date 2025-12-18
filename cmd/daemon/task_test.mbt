///|
test "Task/roundtrip" {
  let json : Json = {
    "name": "example",
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "cwd": "/tmp/example",
    "port": 8080,
    "status": "idle",
    "created": 0,
    "web_search": true,
    "queued_messages": [{ "id": "msg1", "message": { "text": "Hello" } }],
  }
  let task : @daemon.Task = @json.from_json(json)
  let roundtrip = task.to_json()
  assert_eq(json, roundtrip)
}
