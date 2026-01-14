///|
test "Running::ToJson" {
  let task = Running::{
    name: Some("example"),
    id: @uuid.parse("123e4567-e89b-12d3-a456-426614174000"),
    cwd: "/tmp/example",
    port: 8080,
    status: @server.Idle,
    queued_messages: [
      QueuedMessage::{ id: "msg1", message: { "text": "Hello" } },
    ],
    created: @clock.Timestamp::from_ms(0),
    updated: @clock.Timestamp::from_ms(0),
    web_search: true,
    model: "gpt-4",
    broadcast: @broadcast.Broadcast::new(),
  }
  assert_eq(task.to_json(), {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "cwd": "/tmp/example",
    "port": 8080,
    "status": "idle",
    "updated": 0,
    "created": 0,
    "web_search": true,
    "queued_messages": [{ "id": "msg1", "message": { "text": "Hello" } }],
    "model": "gpt-4",
    "name": "example",
  })
}

///|
test "Running::from_json" {
  let json : Json = {
    "name": "example",
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "cwd": "/tmp/example",
    "port": 8080,
    "status": "idle",
    "updated": 0,
    "created": 0,
    "web_search": true,
    "queued_messages": [{ "id": "msg1", "message": { "text": "Hello" } }],
    "model": "gpt-4",
  }
  let task : Running = @json.from_json(json)
  assert_eq(task.name, Some("example"))
  assert_eq(task.id, @uuid.parse("123e4567-e89b-12d3-a456-426614174000"))
  assert_eq(task.cwd, "/tmp/example")
  assert_eq(task.port, 8080)
  assert_true(task.status is @server.Idle)
  assert_eq(task.created, @clock.Timestamp::from_ms(0))
  assert_eq(task.web_search, true)
  assert_eq(task.model, "gpt-4")
  assert_eq(task.queued_messages.length(), 1)
  assert_eq(task.queued_messages[0].id, "msg1")
  assert_eq(task.queued_messages[0].message, { "text": "Hello" })
}
