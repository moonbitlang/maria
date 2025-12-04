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
    {
      "name": "mock:claude-sonnet-4.5",
      "description": "Claude Sonnet 4.5 is Anthropic’s most advanced Sonnet model to date, optimized for real-world agents and coding workflows.",
      "model_name": "anthropic/claude-sonnet-4.5",
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
async fn configure_server(
  mock : @mock.Context,
  register? : @server.Register,
  serve? : StringView,
  model? : String = "mock:claude-haiku-4.5",
) -> @server.Server {
  let cwd = @os.cwd()
  let serve = match serve {
    Some(serve) => serve.to_string()
    None => @path.join(cwd, "cmd/server")
  }
  configure_models(mock)
  @server.Server::new(model~, serve~, register?, port=0, cwd=mock.cwd.path())
}

///|
#skip
async test "register" (t : @test.Test) {
  @mock.run(t, mock => {
    let addr = @socket.Addr::parse("[::]:0")
    let daemon = @socket.TcpServer::new(addr, dual_stack=true, reuse_addr=true)
    defer daemon.close()
    let server = configure_server(mock, register=@server.Register::{
      host: "localhost",
      port: daemon.addr().port(),
      id: "test-server",
    })
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (conn, _) = daemon.accept()
    let conn = @http.ServerConnection::new(conn)
    let r = conn.read_request()
    guard r.path is "/v1/task/register" else { return }
    let rb = conn.read_all()
    @json.inspect(rb.json(), content={
      "id": "test-server",
      "port": server.port(),
    })
  })
}

///|
#skip
async test "POST /v1/message" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/status")
    @json.inspect(r.code, content=200)
    @json.inspect(b.json(), content={ "status": "idle", "web_search": false })
    let (r, b) = @http.post(
      "http://localhost:\{server.port()}/v1/message",
      Json::object({ "message": { "role": "user", "content": "Hello, Maria!" } }),
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(_), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    @json.inspect(queued, content=true)
    let (r, b) = @http.post(
      "http://localhost:\{server.port()}/v1/message",
      Json::object({ "message": { "role": "user", "content": "Hello again!" } }),
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(qid), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    @json.inspect(queued, content=true)
    let (r, b) = @http.get(
      "http://localhost:\{server.port()}/v1/queued-messages",
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    @json.inspect(b, content=[
      { "id": qid, "message": { "role": "user", "content": "Hello again!" } },
    ])
  })
}

///|
fn redact_events(
  events : Array[Json],
  remove_events? : Array[String] = [],
) -> Array[Json] {
  events
  .filter(event => {
    guard event is Object({ "event": String(ev), .. }) else { return true }
    !remove_events.contains(ev)
  })
  .map(event => {
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
async test "GET /v1/events" (t : @test.Test) {
  @mock.run(t, mock => {
    let group = mock.group
    let server = configure_server(mock)
    group.spawn_bg(() => server.start(), no_wait=true)
    let events : Array[Json] = []
    let collector = group.spawn(() => {
      let (r, s) = @http.get_stream(
        "http://localhost:\{server.port()}/v1/events",
      )
      @json.inspect(r.code, content=200)
      let mut last_event : String? = None
      while s.read_until("\n") is Some(line) {
        match line {
          [.. "event: ", .. event] => {
            last_event = Some(event.to_string())
            continue
          }
          [.. "data: ", .. data] => {
            let data = @json.parse(data)
            if last_event is Some(event) {
              events.push({ "event": event, "data": data })
            } else {
              events.push({ "data": data })
            }
            last_event = None
            if events.last() is Some(event) &&
              event is { "data": { "msg": "PostConversation", .. }, .. } {
              break
            }
          }
          _ => continue
        }
      }
    })
    let (_, b) = @http.post(
      "http://localhost:\{server.port()}/v1/message",
      Json::object({ "message": { "role": "user", "content": "Hello, Maria!" } }),
    )
    let b = b.json()
    guard b is { "id": String(msg0_id), .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    let (_, b) = @http.post(
      "http://localhost:\{server.port()}/v1/message",
      Json::object({
        "message": { "role": "user", "content": "Hello again, Maria!" },
      }),
    )
    let b = b.json()
    guard b is { "id": String(msg1_id), .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    collector.wait()
    fn extract_events_for_message(
      events : Array[Json],
      id : String,
      content : String,
    ) -> Array[Json] {
      events.filter(e => (
          e
          is {
            "event": "maria",
            "data": {
              "msg": "MessageAdded",
              "message": { "content": String(s), .. },
              ..
            }
            | {
              "msg": "MessageQueued",
              "message": { "message": { "content": String(s), .. }, .. },
              ..
            },
            ..
          } &&
          s == content
        ) ||
        (
          e
          is {
            "event": "maria",
            "data": {
              "msg": "MessageUnqueued",
              "message": { "id": String(mid), .. },
              ..
            },
            ..
          } &&
          mid == id
        ))
    }

    @json.inspect(
      redact_events(
        extract_events_for_message(events, msg0_id, "Hello, Maria!"),
      ),
      content=[
        {
          "event": "maria",
          "data": {
            "msg": "MessageQueued",
            "message": {
              "id": "<redacted>",
              "message": { "role": "user", "content": "Hello, Maria!" },
            },
          },
        },
        {
          "event": "maria",
          "data": {
            "msg": "MessageUnqueued",
            "message": { "id": "<redacted>" },
          },
        },
        {
          "event": "maria",
          "data": {
            "msg": "MessageAdded",
            "message": { "role": "user", "content": "Hello, Maria!" },
          },
        },
      ],
    )
    @json.inspect(
      redact_events(
        extract_events_for_message(events, msg1_id, "Hello again, Maria!"),
      ),
      content=[
        {
          "event": "maria",
          "data": {
            "msg": "MessageQueued",
            "message": {
              "id": "<redacted>",
              "message": { "role": "user", "content": "Hello again, Maria!" },
            },
          },
        },
        {
          "event": "maria",
          "data": {
            "msg": "MessageUnqueued",
            "message": { "id": "<redacted>" },
          },
        },
        {
          "event": "maria",
          "data": {
            "msg": "MessageAdded",
            "message": { "role": "user", "content": "Hello again, Maria!" },
          },
        },
      ],
    )
  })
}

///|
async test "GET /v1/moonbit/modules" (t : @test.Test) {
  @mock.run(t, mock => {
    @moon.new(user="username", name="example", mock.cwd.path())
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get(
      "http://localhost:\{server.port()}/v1/moonbit/modules",
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    guard b is { "modules": Array(modules), .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    @json.inspect(mock.json(modules), content=[
      {
        "path": "(mock:cwd)",
        "name": "username/example",
        "version": "0.1.0",
        "description": "",
      },
    ])
  })
}

///|
async test "POST /v1/moonbit/publish" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.post(
      "http://localhost:\{server.port()}/v1/moonbit/publish",
      Json::object({ "module": { "path": mock.cwd.path() } }),
    )
    @json.inspect(r.code, content=404)
    @json.inspect(
      mock.json(b.json()).transform(@json.Replacer::exclude(["metadata"])),
      content={
        "error": {
          "code": -1,
          "message": "No MoonBit module found in path '(mock:cwd)'",
        },
      },
    )
    @moon.new(user="username", name="example", mock.cwd.path())
    let (r, b) = @http.post(
      "http://localhost:\{server.port()}/v1/moonbit/publish",
      Json::object({ "module": { "path": mock.cwd.path() } }),
    )
    @json.inspect(r.code, content=500)
    @json.inspect(
      mock
      .json(b.json())
      .transform(@json.Replacer::exclude(["stdout", "stderr"])),
      content={
        "error": {
          "code": -1,
          "message": "Failed to publish module at '(mock:cwd)'",
          "metadata": {
            "module": {
              "path": "(mock:cwd)",
              "name": "username/example",
              "version": "0.1.0",
              "description": "",
            },
            "process": { "status": 255 },
          },
        },
      },
    )
  })
}

///|
async test "CORS" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let c = @http.Client::new("http://localhost:\{server.port()}")
    defer c.close()
    c.request(Options, "/v1/message")
    let r = c.end_request()
    @json.inspect(r.code, content=204)
    @json.inspect(r.headers["access-control-allow-origin"], content="*")
    @json.inspect(r.headers["access-control-allow-methods"], content="*")
    @json.inspect(r.headers["access-control-allow-headers"], content="*")
  })
}

///|
async test "GET /" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_file("index.html").write_string("<h1>Home Page</h1>")
    let server = configure_server(mock, serve=mock.cwd.path())
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/")
    @json.inspect(r.code, content=200)
    @json.inspect(r.headers["content-type"], content="text/html")
    @json.inspect(b.text(), content="<h1>Home Page</h1>")
  })
}

///|
async test "GET /script.js" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_file("script.js").write_string("console.log('Hello, world!');")
    let server = configure_server(mock, serve=mock.cwd.path())
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/script.js")
    @json.inspect(r.code, content=200)
    @json.inspect(r.headers["content-type"], content="application/javascript")
    @json.inspect(b.text(), content="console.log('Hello, world!');")
  })
}

///|
#skip
async test "POST /v1/cancel" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    let events : Array[Json] = []
    @async.with_task_group(group => {
      group.spawn_bg(() => server.start(), no_wait=true)
      group.spawn_bg(() => {
        let (r, s) = @http.get_stream(
          "http://localhost:\{server.port()}/v1/events",
        )
        @json.inspect(r.code, content=200)
        let mut last_event : String? = None
        while s.read_until("\n") is Some(line) {
          match line {
            [.. "event: ", .. event] => {
              last_event = Some(event.to_string())
              continue
            }
            [.. "data: ", .. data] => {
              let data = @json.parse(data)
              if last_event is Some(event) {
                events.push({ "event": event, "data": data })
              } else {
                events.push({ "data": data })
              }
              last_event = None
              if events.last() is Some(event) &&
                event is { "data": { "msg": "PostConversation", .. }, .. } {
                break
              }
            }
            _ => continue
          }
        }
      })
      let (r, b) = @http.get("http://localhost:\{server.port()}/v1/status")
      @json.inspect(r.code, content=200)
      @json.inspect(b.json(), content={ "status": "idle", "web_search": false })
      let (r, b) = @http.post(
        "http://localhost:\{server.port()}/v1/message",
        Json::object({
          "message": { "role": "user", "content": "Hello, Maria!" },
        }),
      )
      @json.inspect(r.code, content=200)
      let b = b.json()
      guard b is { "id": String(_), "queued": queued, .. } else {
        fail("Invalid response body: \{b.stringify(indent=2)}")
      }
      @json.inspect(queued, content=true)
      let (r, _) = @http.post(
        "http://localhost:\{server.port()}/v1/cancel",
        Json::object({}),
      )
      @json.inspect(r.code, content=200)
      // Should be able to send another message after cancellation
      @http.post(
        "http://localhost:\{server.port()}/v1/message",
        Json::object({
          "message": { "role": "user", "content": "Hello again, Maria!" },
        }),
      )
      |> ignore()
    })
    @json.inspect(redact_events(events), content=[
      { "event": "maria.queued_messages.synchronized", "data": [] },
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
          "msg": "MessageQueued",
          "message": {
            "id": "<redacted>",
            "message": { "role": "user", "content": "Hello, Maria!" },
          },
        },
      },
      { "event": "maria.queued_messages.synchronized", "data": [] },
      { "event": "maria", "data": { "msg": "PreConversation" } },
      {
        "event": "maria",
        "data": { "msg": "MessageUnqueued", "message": { "id": "<redacted>" } },
      },
      { "event": "maria.queued_messages.synchronized", "data": [] },
      {
        "event": "maria",
        "data": {
          "msg": "MessageAdded",
          "message": { "role": "user", "content": "Hello, Maria!" },
        },
      },
      {
        "event": "maria",
        "data": {
          "msg": "MariaCancelled",
          "error": { "code": -1, "message": "Task was cancelled." },
        },
      },
      {
        "event": "maria",
        "data": {
          "msg": "MessageQueued",
          "message": {
            "id": "<redacted>",
            "message": { "role": "user", "content": "Hello again, Maria!" },
          },
        },
      },
      { "event": "maria.queued_messages.synchronized", "data": [] },
      { "event": "maria", "data": { "msg": "PreConversation" } },
      {
        "event": "maria",
        "data": { "msg": "MessageUnqueued", "message": { "id": "<redacted>" } },
      },
      { "event": "maria.queued_messages.synchronized", "data": [] },
      {
        "event": "maria",
        "data": {
          "msg": "MessageAdded",
          "message": { "role": "user", "content": "Hello again, Maria!" },
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
}

///|
async fn collect_events(s : @http.Client) -> Array[Json] {
  let events : Array[Json] = []
  let mut last_event : String? = None
  while s.read_until("\n") is Some(line) {
    match line {
      [.. "event: ", .. event] => {
        last_event = Some(event.to_string())
        continue
      }
      [.. "data: ", .. data] => {
        let data = @json.parse(data)
        if last_event is Some(event) {
          events.push({ "event": event, "data": data })
        } else {
          events.push({ "data": data })
        }
        last_event = None
        if events.last() is Some(event) &&
          event
          is ({
            "data": {
              "msg": "PostConversation"
              | "MariaFailed"
              | "MariaCancelled",
              ..
            },
            ..
          }
          | {
            "data": {
              "msg": "ExternalEventReceived",
              "event": { "type": "UserCancellation", .. },
              ..
            },
            ..
          }) {
          break
        }
      }
      _ => continue
    }
  }
  return events
}

///|
#skip
async test "web_search" (t : @test.Test) {
  @mock.run(t, mock => {
    let group = mock.group
    let server = configure_server(mock)
    group.spawn_bg(() => server.start(), no_wait=true)
    let collector = group.spawn(() => {
      let (r, s) = @http.get_stream(
        "http://localhost:\{server.port()}/v1/events",
      )
      @json.inspect(r.code, content=200)
      collect_events(s)
    })
    let _ = @http.post(
      "http://localhost:\{server.port()}/v1/message",
      Json::object({
        "message": {
          "role": "user",
          "content": "Can you please search the web for MoonBit to find out which year it is initiated?",
        },
        "web_search": true,
      }),
    )
    let events = collector.wait()
    @json.inspect(
      events
      .filter(e => e
        is {
          "event": "maria",
          "data": {
            "msg": "RequestCompleted",
            "message": { "content": String(content), .. },
            ..
          },
          ..
        } &&
        (content.contains("2022") || content.contains("2023")))
      .length() >
      0,
      content=true,
    )
  })
}

///|
#skip
async test "GET /v1/tools" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/tools")
    @json.inspect(r.code, content=200)
    let b = b.json()
    @json.inspect(b, content={
      "execute_command": { "enabled": true },
      "list_files": { "enabled": true },
      "read_file": { "enabled": true },
      "todo": { "enabled": true },
      "search_files": { "enabled": true },
      "meta_write_to_file": { "enabled": true },
    })
    let (r, b) = @http.post(
      "http://localhost:\{server.port()}/v1/enabled-tools",
      Json::array([
        "list_files", "read_file", "todo", "search_files", "meta_write_to_file",
      ]),
    )
    @json.inspect(r.code, content=200)
    @json.inspect(b.json(), content={})
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/tools")
    @json.inspect(r.code, content=200)
    let b = b.json()
    @json.inspect(b, content={
      "execute_command": { "enabled": false },
      "list_files": { "enabled": true },
      "read_file": { "enabled": true },
      "todo": { "enabled": true },
      "search_files": { "enabled": true },
      "meta_write_to_file": { "enabled": true },
    })
  })
}

///|
#skip
async test "GET /v1/system-prompt" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/system-prompt")
    @json.inspect(r.code, content=200)
    let b = b.json()
    @json.inspect(b is String(text) && text.length() > 0, content=true)
    let (r, b) = @http.post(
      "http://localhost:\{server.port()}/v1/system-prompt",
      Json::string("New system prompt."),
    )
    @json.inspect(r.code, content=200)
    @json.inspect(b.json(), content={})
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/system-prompt")
    @json.inspect(r.code, content=200)
    let b = b.json()
    @json.inspect(r.code, content=200)
    @json.inspect(b, content="New system prompt.")
  })
}

///|
#skip
async test "GET /v1/external-event/user-message" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/status")
    @json.inspect(r.code, content=200)
    @json.inspect(b.json(), content={ "status": "idle", "web_search": false })
    let (r, b) = @http.post(
      "http://localhost:\{server.port()}/v1/external-event/user-message",
      Json::object({ "message": "Hello, Maria!" }),
    )
    @json.inspect(r.code, content=200)
    @json.inspect(b.json(), content={ "success": true })
    let (r, b) = @http.get(
      "http://localhost:\{server.port()}/v1/queued-messages",
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    @json.inspect(b, content=[])
  })
}

///|
#skip
async test "GET /v1/external-event/cancel" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let collector = mock.group.spawn(() => {
      let (r, s) = @http.get_stream(
        "http://localhost:\{server.port()}/v1/events",
      )
      @json.inspect(r.code, content=200)
      collect_events(s)
    })
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/status")
    @json.inspect(r.code, content=200)
    @json.inspect(b.json(), content={ "status": "idle", "web_search": false })
    let (r, b) = @http.post(
      "http://localhost:\{server.port()}/v1/message",
      Json::object({
        "message": {
          "role": "user",
          "content": "Can you please tell me when is it now by spawning the 'date' command?",
        },
      }),
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(_), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    @json.inspect(queued, content=true)
    let (r, b) = @http.post(
      "http://localhost:\{server.port()}/v1/message",
      Json::object({
        "message": {
          "role": "user",
          "content": "Can you please tell me what is the current weather in New York?",
        },
      }),
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(_), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    @json.inspect(queued, content=true)
    let (r, _) = @http.post(
      "http://localhost:\{server.port()}/v1/external-event/cancel",
      Json::object({}),
    )
    @json.inspect(r.code, content=200)
    let events = collector.wait()
    @json.inspect(
      events
      .filter(e => e
        is { "event": "maria", "data": { "msg": "MessageUnqueued", .. }, .. })
      .length(),
      content=1,
    )
    @json.inspect(
      events
      .filter(e => e
        is {
          "event": "maria",
          "data": {
            "msg": "ExternalEventReceived",
            "event": { "type": "UserCancellation", .. },
            ..
          },
          ..
        })
      .length(),
      content=1,
    )
  })
}

///|
#skip
async test "GET /v1/external-event/diagnostics" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock, model="mock:claude-haiku-4.5")
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let collector = mock.group.spawn(() => {
      let (r, s) = @http.get_stream(
        "http://localhost:\{server.port()}/v1/events",
      )
      @json.inspect(r.code, content=200)
      collect_events(s)
    })
    mock.add_files({
      "moon.mod.json": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "moon.pkg.json": (
        #|{ }
      ),
      "example.mbt": (
        #|///|
        #|let x : Int = "string"
      ),
      "example2.mbt": (
        #|fn main() {
        #|  let y = "hello"
        #|}
      ),
    })
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics()
    let _ = @http.post(
      "http://localhost:\{server.port()}/v1/message",
      Json::object({
        "message": {
          "role": "user",
          "content": "Can you please fix the MoonBit project so that it is free from errors and warnings?",
        },
      }),
    )
    let _ = @http.post(
      "http://localhost:\{server.port()}/v1/external-event/diagnostics",
      Json::object({ "diagnostics": diagnostics.to_json() }),
    )
    let _ = @http.post(
      "http://localhost:\{server.port()}/v1/external-event/cancel",
      Json::object({}),
    )
    let events = collector.wait()
    @json.inspect(
      events
      .filter(e => e
        is {
          "event": "maria",
          "data": {
            "msg": "ExternalEventReceived",
            "event": { "type": "Diagnostics", "diagnostics": Array(_), .. },
            ..
          },
          ..
        })
      .length() >
      0,
      content=true,
    )
  })
}
