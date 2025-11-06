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
async test "todo_read" (t : @test.Test) {
  @mock.run(t, taco => {
    let todo_list = @todo.new(uuid=taco.uuid, cwd=taco.cwd.path())
    let read_tool = @todo_read.new(todo_list)
    @json.inspect(read_tool.call({}), content=["Ok", { "todos": [] }])
    let write_tool = @todo_write.new(todo_list)
    let _ = write_tool.call({
      "action": "create",
      "content": "A sample task",
      "priority": "medium",
    })
    let result = read_tool.call({})
    @json.inspect(drop_id_and_time(result.to_json()), content=[
      "Ok",
      {
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
    ])
  })
}
