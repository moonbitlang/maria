///|
priv struct Task {
  name : String?
  id : @uuid.Uuid
  cwd : String
  port : Int
  mut status : @server.Status
  created : Int64
}

///|
impl ToJson for Task with to_json(self : Task) -> Json {
  {
    "name": self.name,
    "id": self.id.to_string(),
    "cwd": self.cwd,
    "port": self.port,
    "status": self.status,
    "created": Json::number(
      self.created.to_double(),
      repr=self.created.to_string(),
    ),
  }
}

///|
test "Task::ToJson" {
  let task = Task::{
    name: Some("example"),
    id: @uuid.parse("123e4567-e89b-12d3-a456-426614174000"),
    cwd: "/tmp/example",
    port: 8080,
    status: @server.Idle,
    created: 0,
  }
  @json.inspect(task, content={
    "name": ["example"],
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "cwd": "/tmp/example",
    "port": 8080,
    "status": "idle",
    "created": 0,
  })
}
