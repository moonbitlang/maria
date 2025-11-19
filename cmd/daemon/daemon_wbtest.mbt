///|
#skip
async test "GET /v1/tasks" {
  let daemon = Daemon::new(
    exec_path="./target/native/release/build/cmd/server/server.exe",
    port=0,
    serve="./cmd/daemon",
  )
  @async.with_task_group(group => {
    group.spawn_bg(() => daemon.serve(), no_wait=true)
    @async.pause()
    let (r, b) = @http.get("http://localhost/v1/tasks", port=daemon.port)
    @json.inspect(r.code, content=200)
    @json.inspect(r.headers, content={
      "content-type": "application/json",
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET, OPTIONS, POST",
      "access-control-allow-headers": "Content-Type",
      "transfer-encoding": "chunked",
    })
    @json.inspect(b.json(), content={ "tasks": [] })
  })
}

///|
#skip
async test "POST /v1/task" {
  let daemon = Daemon::new(
    exec_path="./target/native/release/build/cmd/server/server.exe",
    port=0,
    serve="./cmd/daemon",
  )
  @async.with_task_group(group => {
    group.spawn_bg(() => daemon.serve(), no_wait=true)
    @async.pause()
    let (r, b) = @http.post(
      "http://localhost/v1/task",
      Json::object({ "message": { "role": "user", "content": "Hello!" } }),
      port=daemon.port,
    )
    @json.inspect(r.code, content=201)
    let b = b.json()
    guard b
      is {
        "task": {
          "id": String(id),
          "port": Number(_, ..),
          "status": status,
          "created": Number(_, ..),
          ..
        },
        ..
      } else {
      fail("Unexpected response body: \{b.stringify(indent=2)}")
    }
    let status : @server.Status = @json.from_json(status)
    @json.inspect(status, content="idle")
    let (r, b) = @http.get("http://localhost/v1/tasks", port=daemon.port)
    @json.inspect(r.code, content=200)
    let b = b.json()
    guard b is { "tasks": Array(tasks), .. } else {
      fail("Unexpected response body: \{b.stringify(indent=2)}")
    }
    @json.inspect(tasks.length(), content=1)
    let (r, s) = @http.get_stream(
      "http://localhost/v1/task/\{id}/events",
      port=daemon.port,
    )
    @json.inspect(r.code, content=200)
    @json.inspect(r.headers["content-type"], content="text/event-stream")
    @json.inspect(r.headers["access-control-allow-origin"], content="*")
    @json.inspect(
      r.headers["access-control-allow-methods"],
      content="GET, OPTIONS, POST",
    )
    @json.inspect(
      r.headers["access-control-allow-headers"],
      content="Content-Type",
    )
    @json.inspect(r.headers["x-accel-buffering"], content="no")
    while s.read_until("\n") is Some(line) {
      guard line is [.. "data: ", .. line] else { continue }
      let data = @json.parse(line)
      if data is { "msg": "PostConversation", .. } {
        break
      }
    }
  })
}

///|
#skip
async test "POST /v1/task/{id}/message" {
  let daemon = Daemon::new(
    exec_path="./target/native/release/build/cmd/server/server.exe",
    port=0,
    serve="./cmd/daemon",
  )
  @async.with_task_group(group => {
    group.spawn_bg(() => daemon.serve(), no_wait=true)
    @async.pause()
    let (r, b) = @http.post(
      "http://localhost/v1/task",
      Json::object({ "message": { "role": "user", "content": "Hello!" } }),
      port=daemon.port,
    )
    @json.inspect(r.code, content=201)
    let b = b.json()
    guard b is { "task": { "id": String(id), .. }, .. } else {
      fail("Unexpected response body: \{b.stringify(indent=2)}")
    }
    let (_, b) = @http.post(
      "http://localhost/v1/task/\{id}/message",
      Json::object({ "message": { "role": "user", "content": "How are you?" } }),
      port=daemon.port,
    )
    let b = b.json()
    guard b is { "id": String(msg_id), "queued": queued, .. } else {
      fail("Unexpected response body: \{b.stringify(indent=2)}")
    }
    let queued : Bool = @json.from_json(queued)
    @json.inspect(queued, content=true)
    let (_, s) = @http.get_stream(
      "http://localhost/v1/task/\{id}/events",
      port=daemon.port,
    )
    let pop_ids : Array[String] = []
    while s.read_until("\n") is Some(line) {
      guard line is [.. "data: ", .. line] else { continue }
      let data = @json.parse(line)
      match data {
        { "msg": "PostConversation", .. } => break
        { "msg": "MessageUnqueued", "message": { "id": String(id), .. }, .. } =>
          pop_ids.push(id)
        _ => ()
      }
    }
    @json.inspect(pop_ids, content=[msg_id])
  })
}
