///|
fn[T : ToJson] drop_id(json : T) -> Json {
  let json = json.to_json()
  if json is Object(obj) {
    let obj = obj.map((key, value) => if key == "id" {
      String("...")
    } else {
      drop_id(value)
    })
    Json::object(obj)
  } else if json is Array(arr) {
    Json::array(arr.map(item => drop_id(item)))
  } else {
    json
  }
}

///|
fn[T : ToJson] drop_time(json : T) -> Json {
  let json = json.to_json()
  if json is Object(obj) {
    let obj = obj.map((key, value) => if key == "created_at" ||
      key == "updated_at" {
      String("...")
    } else {
      drop_time(value)
    })
    Json::object(obj)
  } else if json is Array(arr) {
    Json::array(arr.map(item => drop_time(item)))
  } else {
    json
  }
}

///|
fn[T : ToJson] drop_id_and_time(json : T) -> Json {
  drop_id(drop_time(json))
}

///|
async test "todo_read" (t : @test.T) {
  @mock.run(t, taco => {
    let todo_list = @todo.list(uuid=taco.uuid, cwd=taco.cwd.path())
    @json.inspect(@todo_read.todo_read.call({}, todo_list), content={
      "output": { "todos": [] },
    })
    @json.inspect(@todo_read.todo_read.call({}, todo_list), content={
      "output": { "todos": [] },
    })
    let _ = @todo_write.todo_write.call(
      { "action": "create", "content": "A sample task", "priority": "medium" },
      todo_list,
    )
    let result = @todo_read.todo_read.call({}, todo_list)
    @json.inspect(drop_id_and_time(result.to_json()), content={
      "output": {
        "todos": [
          {
            "content": "A sample task",
            "created_at": "...",
            "id": "...",
            "priority": "Medium",
            "status": "Pending",
            "updated_at": "...",
          },
        ],
      },
    })
  })
}
