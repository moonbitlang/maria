///|
priv enum DaemonEvent {
  TasksSynchronized(Array[@daemon.Task])
  TaskChanged(@daemon.Task)
} derive(ToJson)

///|
impl @httpx.FromEvent for DaemonEvent with from_event(event : @httpx.Event) -> DaemonEvent raise {
  let { event, data } = event
  let data = @json.parse(data)
  match event {
    Some("daemon.task.changed") => {
      guard data is { "task": task, .. } else {
        fail("Invalid task changed event data")
      }
      TaskChanged(@json.from_json(task))
    }
    Some("daemon.tasks.synchronized") => {
      guard data is { "tasks": tasks, .. } else {
        fail("Invalid tasks synchronized event data")
      }
      TasksSynchronized(@json.from_json(tasks))
    }
    _ => fail("unrecognized daemon event type: \{event}")
  }
}

///|
async fn DaemonEvent::collect_events(s : @http.Client) -> Array[DaemonEvent] {
  @test_utils.collect_events(s, stop_at=event => if event is TaskChanged(task) &&
    task.is_idle() {
    return true
  } else {
    return false
  })
}

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
      "api_key": mock.getenv("OPENROUTER_API_KEY"),
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
    exec_path=@pathx.join(
      os_cwd, "target/native/release/build/cmd/main/main.exe",
    ),
    port=0,
    serve=@pathx.join(os_cwd, "cmd/daemon"),
    lock=false,
  ).unwrap()
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
      guard r.headers
        is {
          "content-type": "application/json",
          "access-control-allow-origin": "*",
          "access-control-allow-methods": "*",
          "access-control-allow-headers": "*",
          "transfer-encoding": "chunked",
          ..
        } else {
        fail("Unexpected response headers: \{r.headers}")
      }
      @json.inspect(b.json(), content={ "tasks": [] })
      let _ = @httpx.post_json("http://localhost:\{daemon.port()}/v1/task", {
        "message": { "role": "user", "content": "Hello!" },
        "model": "mock:claude-haiku-4.5",
        "cwd": mock.cwd.path(),
      })
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
      let (_, b) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task",
        {
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        },
      )
      let b = b.json()
      guard b is { "task": { "id": String(id), .. }, .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      let _ = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/message",
        { "message": { "role": "user", "content": "How are you?" } },
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
      guard r.headers
        is {
          "content-type": "application/json",
          "access-control-allow-origin": "*",
          "access-control-allow-methods": "*",
          "access-control-allow-headers": "*",
          "transfer-encoding": "chunked",
          ..
        } else {
        fail("Unexpected response headers: \{r.headers}")
      }
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
      let (r, b) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task",
        {
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        },
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
      ignore(@test_utils.ServerEvent::collect_events(s))
    })
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
      let (r, b) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task",
        {
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        },
      )
      @json.inspect(r.code, content=201)
      let b = b.json()
      guard b
        is {
          "task": { "id": String(id), .. },
          "message": { "id": String(msg0_id), .. },
          ..
        } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      let (_, b) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/message",
        { "message": { "role": "user", "content": "How are you?" } },
      )
      let b = b.json()
      guard b is { "id": String(msg1_id), "queued": queued, .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      let queued : Bool = @json.from_json(queued)
      @json.inspect(queued, content=true)
      let (_, s) = @http.get_stream(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/events",
      )
      let pop_ids : Array[@uuid.Uuid] = []
      let events = @test_utils.ServerEvent::collect_events(s)
      for event in events {
        if event is Maria(event) && event.desc is MessageUnqueued(id~) {
          pop_ids.push(id)
        }
      }
      @json.inspect(pop_ids, content=[msg0_id, msg1_id])
      @json.inspect(
        @test_utils.redact_events(
          @test_utils.extract_events_for_message(
            events,
            id=msg0_id,
            content="Hello!",
          ),
        ),
        content=[
          [
            "Maria",
            {
              "id": "00000000-0000-0000-0000-000000000000",
              "desc": {
                "msg": "MessageQueued",
                "message": { "id": "00000000-0000-0000-0000-000000000000" },
              },
            },
          ],
          [
            "Maria",
            {
              "id": "00000000-0000-0000-0000-000000000000",
              "desc": {
                "msg": "MessageUnqueued",
                "message": { "id": "00000000-0000-0000-0000-000000000000" },
              },
            },
          ],
          [
            "Maria",
            {
              "id": "00000000-0000-0000-0000-000000000000",
              "desc": { "msg": "UserMessage", "content": "<redacted>" },
            },
          ],
        ],
      )
      @json.inspect(
        @test_utils.redact_events(
          @test_utils.extract_events_for_message(
            events,
            id=msg1_id,
            content="How are you?",
          ),
        ),
        content=[
          [
            "Maria",
            {
              "id": "00000000-0000-0000-0000-000000000000",
              "desc": {
                "msg": "MessageQueued",
                "message": { "id": "00000000-0000-0000-0000-000000000000" },
              },
            },
          ],
          [
            "Maria",
            {
              "id": "00000000-0000-0000-0000-000000000000",
              "desc": {
                "msg": "MessageUnqueued",
                "message": { "id": "00000000-0000-0000-0000-000000000000" },
              },
            },
          ],
          [
            "Maria",
            {
              "id": "00000000-0000-0000-0000-000000000000",
              "desc": { "msg": "UserMessage", "content": "<redacted>" },
            },
          ],
        ],
      )
      @json.inspect(
        @test_utils.redact_events(events)
        .filter(e => {
          guard e is MariaQueuedMessagesSynchronized(msgs) else { false }
          msgs
          .filter(msg => msg
            is { "message": { "content": "How are you?", .. }, .. })
          .length() >
          0
        })
        .length() >
        0,
        content=true,
      )
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
      let (r, b) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task",
        {
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": "/non/existent/path",
        },
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
      let (r, b) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task",
        {
          "message": { "role": "user", "content": "Hello!" },
          "model": "nonexistent-model",
          "cwd": mock.cwd.path(),
        },
      )
      @json.inspect(r.code, content=201)
      let b = b.json()
      @json.inspect(
        b
        is {
          "task": {
            "name": _,
            "id": String(_),
            "cwd": String(_),
            "port": Number(_, ..),
            "status": "idle"
            | "generating",
            "created": Number(_, ..),
            "web_search": false,
            ..
          },
          "message": { "id": String(_), "queued": true | false, .. },
          ..
        },
        content=true,
      )
    })
  })
}

///|
#skip
async test "GET /v1/events" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      let collector = group.spawn(() => {
        let (_, s) = @http.get_stream(
          "http://localhost:\{daemon.port()}/v1/events",
        )
        DaemonEvent::collect_events(s)
      })
      let (_, b) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task",
        {
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        },
      )
      guard b.json() is { "task": { "id": String(id), .. }, .. } else {
        fail("Unexpected response body: \{b.json().stringify(indent=2)}")
      }
      @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/message",
        { "message": { "role": "user", "content": "How are you?" } },
      )
      |> ignore()
      let events = collector.wait()
      @json.inspect(
        mock
        .json(events)
        .transform(@json.Replacer::exclude(["port", "created"])),
        content=[
          ["TasksSynchronized", []],
          [
            "TaskChanged",
            {
              "name": null,
              "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
              "cwd": "(mock:cwd)",
              "status": "generating",
              "web_search": false,
              "queued_messages": [],
            },
          ],
          [
            "TaskChanged",
            {
              "name": null,
              "id": "ac8a366d-ce7e-47d9-8bc7-27c69e416f1a",
              "cwd": "(mock:cwd)",
              "status": "idle",
              "web_search": false,
              "queued_messages": [],
            },
          ],
        ],
      )
    })
  })
}

///|
#skip
async test "POST /v1/task/{id}/cancel" (t : @test.Test) {
  @mock.run(t, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      @async.pause()
      let (r, b) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task",
        {
          "message": { "role": "user", "content": "Hello!" },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
        },
      )
      @json.inspect(r.code, content=201)
      let b = b.json()
      guard b is { "task": { "id": String(id), .. }, .. } else {
        fail("Unexpected response body: \{b.stringify(indent=2)}")
      }
      let collector = group.spawn(() => {
        let (_, s) = @http.get_stream(
          "http://localhost:\{daemon.port()}/v1/task/\{id}/events",
        )
        @test_utils.ServerEvent::collect_events(s)
      })
      let (r, _) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task/\{id}/cancel",
        null,
      )
      @json.inspect(r.code, content=200)
      let events = collector.wait()
      @json.inspect(
        events.filter(event => event is Maria({ desc: Cancelled, .. })).length() >
        0,
        content=true,
      )
    })
  })
}

///|
/// This test requires `cmd/test-to-be-killed` to be built. Skipped by default.
#skip
async test "kill older, non-responsive daemon" (t : @test.Test) {
  let exec_path = "target/native/release/build/cmd/test-to-be-killed/test-to-be-killed.exe"
  let exec_path = @fsx.resolve(exec_path)
  @mock.run(t, mock => {
    let manager = @spawn.Manager::new(cwd=mock.cwd.path())
    mock.group.spawn_bg(() => @async.with_timeout(20_000, () => manager.start()))
    let process = manager.spawn(exec_path, [], env={ "HOME": mock.cwd.path() })
    mock.group.spawn_bg(() => @async.with_timeout(20_000, () => process.wait()
      |> ignore()))
    @async.sleep(1_000)
    let _ = configure_daemon(mock)
    mock.group.return_immediately(())
  })
}

///|
#skip
#cfg(false)
async test "POST /v1/task/{id} with web_search" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    let daemon = configure_daemon(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => daemon.serve(), no_wait=true)
      let (_, b) = @httpx.post_json(
        "http://localhost:\{daemon.port()}/v1/task",
        {
          "message": {
            "role": "user",
            "content": "Can you please search the web for MoonBit to find out which year it is initiated?",
          },
          "model": "mock:claude-haiku-4.5",
          "cwd": mock.cwd.path(),
          "web_search": true,
        },
      )
      guard b.json()
        is { "task": { "id": String(id), "web_search"? : web_search, .. }, .. } else {
        fail("Unexpected response body: \{b.json().stringify(indent=2)}")
      }
      let collector = group.spawn(() => {
        let (_, s) = @http.get_stream(
          "http://localhost:\{daemon.port()}/v1/task/\{id}/events",
        )
        @test_utils.ServerEvent::collect_events(s)
      })
      @json.inspect(web_search, content=[true])
      let events = collector.wait()
      let content = events
        .filter_map(e => if e
          is Maria({ desc: AssistantMessage(content, ..), .. }) {
          Some(content)
        } else {
          None
        })
        .join("\n")
      @json.inspect(
        content.contains("2022") || content.contains("2023"),
        content=true,
      )
    })
  })
}
