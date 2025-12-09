///|
test "Stopped::to_json" {
  let task = Stopped::{
    name: Some("example"),
    id: @uuid.parse("123e4567-e89b-12d3-a456-426614174000"),
    cwd: "/tmp/example",
    created: @clock.Timestamp::from_ms(0),
    updated: @clock.Timestamp::from_ms(100),
    web_search: true,
    broadcast: @broadcast.Broadcast::new(),
  }
  assert_eq(task.to_json(), {
    "name": "example",
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "cwd": "/tmp/example",
    "status": "stopped",
    "created": 0,
    "updated": 100,
    "web_search": true,
  })
}
