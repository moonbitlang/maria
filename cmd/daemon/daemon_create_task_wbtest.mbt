///|
test "CreateTaskRequest::from_json" {
  let json : Json = {
    "name": "Test Task",
    "model": "gpt-4",
    "message": { "role": "user", "content": "Hello, world!" },
    "cwd": "/tmp/task",
  }
  let request : CreateTaskRequest = @json.from_json(json)
  @json.inspect(request.name, content=["Test Task"])
  @json.inspect(request.model, content=["gpt-4"])
  @json.inspect(request.message, content=[
    { "role": "user", "content": "Hello, world!" },
  ])
  @json.inspect(request.cwd, content=["/tmp/task"])
  let json : Json = {}
  let request : CreateTaskRequest = @json.from_json(json)
  @json.inspect(request.name, content=null)
  @json.inspect(request.model, content=null)
  @json.inspect(request.message, content=null)
  @json.inspect(request.cwd, content=null)
  let json : Json = {
    "name": null,
    "model": null,
    "message": null,
    "cwd": null,
  }
  let request : CreateTaskRequest = @json.from_json(json)
  @json.inspect(request.name, content=null)
  @json.inspect(request.model, content=null)
  @json.inspect(request.message, content=null)
  @json.inspect(request.cwd, content=null)
  @json.inspect(request.web_search, content=null)
  let json : Json = { "web_search": true }
  let request : CreateTaskRequest = @json.from_json(json)
  @json.inspect(request.web_search, content=[true])
}

///|
test "CreateTaskResponse::to_json" {
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
  let response = CreateTaskResponse::{
    task,
    message: Some(
      @server.CreateMessageResponse::new(
        id=@uuid.parse("223e4567-e89b-12d3-a456-426614174000"),
        queued=true,
      ),
    ),
  }
  @json.inspect(response, content={
    "task": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "cwd": "/tmp/example",
      "port": 8080,
      "status": "idle",
      "created": 0,
      "updated": 0,
      "web_search": true,
      "queued_messages": [{ "id": "msg1", "message": { "text": "Hello" } }],
      "model": "gpt-4",
      "name": "example",
    },
    "message": { "id": "223e4567-e89b-12d3-a456-426614174000", "queued": true },
  })
}
