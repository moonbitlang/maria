///|
async fn configure_models(mock : @mock.Context) -> Unit {
  mock.cwd
  .add_directory(".moonagent")
  .add_directory("models")
  .add_file("models.json")
  .write_json([
    {
      "name": "mock:claude-haiku-4.5",
      "description": "Claude Haiku 4.5 is Anthropic’s fastest and most efficient model, delivering near-frontier intelligence at a fraction of the cost and latency of larger Claude models. Matching Claude Sonnet 4’s performance across reasoning, coding, and computer-use tasks, Haiku 4.5 brings frontier-level capability to real-time and high-volume applications. It introduces extended thinking to the Haiku line; enabling controllable reasoning depth, summarized or interleaved thought output, and tool-assisted workflows with full support for coding, bash, web search, and computer-use tools. Scoring >73% on SWE-bench Verified, Haiku 4.5 ranks among the world’s best coding models while maintaining exceptional responsiveness for sub-agents, parallelized execution, and scaled deployment.",
      "model_name": "anthropic/claude-haiku-4.5",
      "model_type": "saas/openai",
      "base_url": "https://openrouter.ai/api/v1",
      "is_reasoning": false,
      "input_price": 21.0,
      "output_price": 105.0,
      "average_speed": 0,
      "safe_zone_tokens": 128000,
      "max_output_tokens": 24288,
      "supports_anthropic_prompt_caching": true,
    },
  ])
}

///|
async fn configure_daemon(mock : @mock.Context) -> Daemon {
  let os_cwd = @os.cwd()
  configure_models(mock)
  @daemon.Daemon::new(
    uuid=mock.uuid,
    cwd=mock.cwd.path(),
    exec_path=@path.join(
      os_cwd, "target/native/release/build/cmd/main/main.exe",
    ),
    port=0,
    serve=@path.join(os_cwd, "cmd/daemon"),
  )
}

///|
#skip
async test "GET /v1/tasks" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      @async.pause()
      let (r, b) = @http.get("http://localhost:\{daemon.port()}/v1/tasks")
      @json.inspect(r.code, content=200)
      @json.inspect(r.headers, content={
        "content-type": "application/json",
        "access-control-allow-origin": "*",
        "access-control-allow-methods": "*",
        "access-control-allow-headers": "*",
        "transfer-encoding": "chunked",
      })
      @json.inspect(b.json(), content={ "tasks": [] })
      let _ = @http.post(
        "http://localhost:\{daemon.port()}/v1/task",
        Json::object({
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        }),
      )
      let (_, b) = @http.get("http://localhost:\{daemon.port()}/v1/tasks")
      let b = b.json()
      guard b is { "tasks": Array(tasks), .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      @json.inspect(tasks.length(), content=1)
    })
  })
}

///|
#skip
async test "GET /v1/task/{id}" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      @async.pause()
      let (_, b) = @http.post(
        "http://localhost:\{daemon.port()}/v1/task",
        Json::object({
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        }),
      )
      let b = b.json()
      guard b is { "task": { "id": String(id), .. }, .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      let _ = @http.post(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/message",
        Json::object({
          "message": { "role": "user", "content": "How are you?" },
        }),
      )
      let (_, b) = @http.get("http://localhost:\{daemon.port()}/v1/task/\{id}")
      let b = b.json()
      guard b
        is { "task": { "queued_messages": Array(queued_messages), .. }, .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      let queued_messages = queued_messages.map(m => if m
        is Object({ "id": _, .. } as m) {
        m["id"] = "<redacted>"
        Json::object(m)
      } else {
        m
      })
      @json.inspect(queued_messages, content=[
        {
          "id": "<redacted>",
          "message": { "role": "user", "content": "How are you?" },
        },
      ])
    })
  })
}

///|
#skip
async test "GET /v1/models" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      @async.pause()
      let (r, b) = @http.get("http://localhost:\{daemon.port()}/v1/models")
      @json.inspect(r.code, content=200)
      @json.inspect(r.headers, content={
        "content-type": "application/json",
        "access-control-allow-origin": "*",
        "access-control-allow-methods": "*",
        "access-control-allow-headers": "*",
        "transfer-encoding": "chunked",
      })
      let b = b.json()
      guard b is { "models": Array(models), .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      @json.inspect(
        models.contains({ "name": "mock:claude-haiku-4.5" }),
        content=true,
      )
    })
  })
}

///|
#skip
async test "POST /v1/task" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      @async.pause()
      let (r, b) = @http.post(
        "http://localhost:\{daemon.port()}/v1/task",
        Json::object({
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        }),
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
      let (r, b) = @http.get("http://localhost:\{daemon.port()}/v1/tasks")
      @json.inspect(r.code, content=200)
      let b = b.json()
      guard b is { "tasks": Array(tasks), .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      @json.inspect(tasks.length(), content=1)
      let (r, s) = @http.get_stream(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/events",
      )
      @json.inspect(r.code, content=200)
      @json.inspect(r.headers["content-type"], content="text/event-stream")
      @json.inspect(r.headers["access-control-allow-origin"], content="*")
      @json.inspect(r.headers["access-control-allow-methods"], content="*")
      @json.inspect(r.headers["access-control-allow-headers"], content="*")
      @json.inspect(r.headers["x-accel-buffering"], content="no")
      while s.read_until("\n") is Some(line) {
        guard line is [.. "data: ", .. line] else { continue }
        let data = @json.parse(line)
        if data is { "msg": "PostConversation", .. } {
          break
        }
      }
    })
  })
}

///|
fn redact_events(events : Array[Json]) -> Array[Json] {
  events.map(event => {
    if event
      is Object(
        { "event": "maria.queued_messages.synchronized", "data": Array(ms), .. } as event
      ) {
      for m in ms {
        if m is Object({ "id": String(_), .. } as message) {
          message["id"] = "<redacted>"
        }
      }
      event["data"] = Json::array(ms)
      return Json::object(event)
    }
    guard event is Object({ "data": Object(data), .. } as event) else {
      return event
    }
    data.remove("id")
    data.remove("tag")
    data.remove("time")
    data.remove("pid")
    data.remove("hostname")
    data.remove("level")
    let data : Map[String, Json] = match data {
      {
        "msg": "MessageAdded",
        "message": Object(
          { "role": "assistant" | "system", "content": String(_), .. } as message
        ),
        ..
      } => {
        message["content"] = "<redacted>"
        { "msg": "MessageAdded", "message": message }
      }
      {
        "msg": String("MessageUnqueued" | "MessageQueued" as msg),
        "message": Object({ "id": String(_), .. } as message),
        ..
      } => {
        message["id"] = "<redacted>"
        { "msg": msg, "message": message }
      }
      { "msg": "RequestCompleted", .. } => {
        data["usage"] = "<redacted>"
        data["message"] = "<redacted>"
        data
      }
      data => data
    }
    event["data"] = Json::object(data)
    Json::object(event)
  })
}

///|
#skip
async test "POST /v1/task/{id}/message" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      @async.pause()
      let (r, b) = @http.post(
        "http://localhost:\{daemon.port()}/v1/task",
        Json::object({
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        }),
      )
      @json.inspect(r.code, content=201)
      let b = b.json()
      guard b is { "task": { "id": String(id), .. }, .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      let (_, b) = @http.post(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/message",
        Json::object({
          "message": { "role": "user", "content": "How are you?" },
        }),
      )
      let b = b.json()
      guard b is { "id": String(msg_id), "queued": queued, .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      let queued : Bool = @json.from_json(queued)
      @json.inspect(queued, content=true)
      let (_, s) = @http.get_stream(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/events",
      )
      let pop_ids : Array[String] = []
      let events : Array[Json] = []
      let mut last_event : String? = None
      while s.read_until("\n") is Some(line) {
        if line is [.. "event: ", .. event] {
          last_event = Some(event.to_string())
          continue
        }
        guard line is [.. "data: ", .. line] else { continue }
        let data = @json.parse(line)
        if last_event is Some(event) {
          events.push({ "event": event, "data": data })
        } else {
          events.push({ "data": data })
        }
        last_event = None
        match data {
          { "msg": "PostConversation", .. } => break
          { "msg": "MessageUnqueued", "message": { "id": String(id), .. }, .. } =>
            pop_ids.push(id)
          _ => ()
        }
      }
      @json.inspect(pop_ids, content=[msg_id])
      @json.inspect(redact_events(events), content=[
        {
          "event": "maria.queued_messages.synchronized",
          "data": [
            {
              "id": "<redacted>",
              "message": { "role": "user", "content": "How are you?" },
            },
          ],
        },
        {
          "event": "maria",
          "data": {
            "msg": "MessageAdded",
            "message": { "role": "system", "content": "<redacted>" },
          },
        },
        {
          "event": "maria",
          "data": {
            "msg": "MessageAdded",
            "message": { "role": "user", "content": "Hello!" },
          },
        },
        { "event": "maria", "data": { "msg": "PreConversation" } },
        {
          "event": "maria",
          "data": {
            "msg": "MessageQueued",
            "message": {
              "id": "<redacted>",
              "message": { "role": "user", "content": "How are you?" },
            },
          },
        },
        {
          "event": "maria.queued_messages.synchronized",
          "data": [
            {
              "id": "<redacted>",
              "message": { "role": "user", "content": "How are you?" },
            },
          ],
        },
        {
          "event": "maria",
          "data": {
            "msg": "RequestCompleted",
            "usage": "<redacted>",
            "message": "<redacted>",
          },
        },
        {
          "event": "maria",
          "data": {
            "msg": "MessageUnqueued",
            "message": { "id": "<redacted>" },
          },
        },
        { "event": "maria.queued_messages.synchronized", "data": [] },
        {
          "event": "maria",
          "data": {
            "msg": "MessageAdded",
            "message": { "role": "user", "content": "How are you?" },
          },
        },
        {
          "event": "maria",
          "data": {
            "msg": "RequestCompleted",
            "usage": "<redacted>",
            "message": "<redacted>",
          },
        },
        { "event": "maria", "data": { "msg": "PostConversation" } },
      ])
    })
  })
}

///|
#skip
async test "POST /v1/task with invalid cwd" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      @async.pause()
      let (r, b) = @http.post(
        "http://localhost:\{daemon.port()}/v1/task",
        Json::object({
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": "/non/existent/path",
        }),
      )
      @json.inspect(r.code, content=404)
      let b = b.json()
      @json.inspect(b, content={
        "error": {
          "code": -1,
          "message": "Specified 'cwd' path does not exist: /non/existent/path",
          "metadata": { "cwd": "/non/existent/path" },
        },
      })
    })
  })
}

///|
#skip
async test "POST /v1/task with invalid model" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      @async.pause()
      let (r, b) = @http.post(
        "http://localhost:\{daemon.port()}/v1/task",
        Json::object({
          "message": { "role": "user", "content": "Hello!" },
          "model": "nonexistent-model",
          "cwd": mock.cwd.path(),
        }),
      )
      @json.inspect(r.code, content=404)
      let b = b.json()
      @json.inspect(b, content={
        "error": {
          "code": -1,
          "message": "Model not found: Some(\"nonexistent-model\")",
        },
      })
    })
  })
}

///|
#skip
async test "GET /v1/events" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    let event_lines : Array[Json] = []
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      group.spawn_bg(() => {
        let (_, s) = @http.get_stream(
          "http://localhost:\{daemon.port()}/v1/events",
        )
        while s.read_until("\n") is Some(line) {
          match line {
            [.. "data: ", .. data] => {
              let data = @json.parse(data)
              event_lines.push({ "data": data })
            }
            [.. "event: ", .. event] =>
              event_lines.push({ "event": event.to_string() })
            _ => continue
          }
          if event_lines
            is [
              ..,
              { "event": "daemon.task.changed", .. },
              { "data": { "task": { "status": "idle", .. }, .. }, .. },
            ] {
            break
          }
        }
      })
      let (_, b) = @http.post(
        "http://localhost:\{daemon.port()}/v1/task",
        Json::object({
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        }),
      )
      guard b.json() is { "task": { "id": String(id), .. }, .. } else {
        fail("Unexpected response body: \{b.json().stringify(indent=2)}")
      }
      @http.post(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/message",
        Json::object({
          "message": { "role": "user", "content": "How are you?" },
        }),
      )
      |> ignore()
    })
    @json.inspect(
      event_lines
      .to_json()
      .transform(@json.Replacer::exclude(["id", "cwd", "port", "created"])),
      content=[
        { "event": "daemon.tasks.synchronized" },
        { "data": { "tasks": [] } },
        { "event": "daemon.task.changed" },
        { "data": { "task": { "name": null, "status": "generating" } } },
        { "event": "daemon.task.changed" },
        { "data": { "task": { "name": null, "status": "idle" } } },
      ],
    )
  })
}
