///|
async fn configure_models(mock : @mock.Context) -> Unit {
  let json : Json = [
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
  ]
  mock.cwd.add_json_tree({
    ".moonagent": { "models": { "models.json": json.stringify() } },
  })
}

///|
async fn configure_server(
  mock : @mock.Context,
  register? : @server.RegisterInfo,
  serve? : StringView,
  model? : String = "mock:claude-haiku-4.5",
) -> @server.Server {
  let cwd = @os.cwd()
  let serve = match serve {
    Some(serve) => serve.to_string()
    None => @pathx.join(cwd, "cmd/server")
  }
  configure_models(mock)
  @server.Server::new(
    model~,
    serve~,
    register?,
    port=0,
    home=mock.cwd.path(),
    cwd=mock.cwd.path(),
  )
}

///|
#skip
async test "register" (t : @test.Test) {
  @mock.run(t, mock => {
    let addr = @socket.Addr::parse("0.0.0.0:0")
    let daemon = @socket.TcpServer::new(addr, dual_stack=true, reuse_addr=true)
    defer daemon.close()
    let server_task = mock.group.spawn(() => {
      configure_server(mock, register=@server.RegisterInfo::{
        host: "localhost",
        port: daemon.addr().port(),
        id: "test-server",
      })
    })
    let (conn, _) = daemon.accept()
    let conn = @http.ServerConnection::new(conn)
    let r = conn.read_request()
    guard r.path is "/v1/task/register" else { return }
    let rb = conn.read_all()
    let res : @server.RegisterResponse = @server.RegisterResponse::{  }
    conn.send_response(200, "OK", extra_headers={
      "Content-Type": "application/json",
    })
    conn.write(res.to_json())
    conn.end_response()
    let server = server_task.wait()
    json_inspect(
      mock.json(rb.json()).transform(@json.Replacer::exclude(["new_id"])),
      content={
        "id": "test-server",
        "port": server.port(),
        "cwd": "(mock:cwd)",
        "web_search": false,
        "model": "mock:claude-haiku-4.5",
      },
    )
  })
}

///|
#skip
async test "POST /v1/message" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/status")
    json_inspect(r.code, content=200)
    json_inspect(b.json(), content={ "status": "idle", "web_search": false })
    let (r, b) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/message",
      { "message": { "role": "user", "content": "Hello, Maria!" } },
    )
    json_inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(_), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    json_inspect(queued, content=false)
    let (r, b) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/message",
      { "message": { "role": "user", "content": "Hello again!" } },
    )
    json_inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(qid), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    json_inspect(queued, content=true)
    let (r, b) = @http.get(
      "http://localhost:\{server.port()}/v1/queued-messages",
    )
    json_inspect(r.code, content=200)
    let b = b.json()
    json_inspect(b, content=[
      { "id": qid, "message": { "role": "user", "content": "Hello again!" } },
    ])
  })
}

///|
#skip
async test "GET /v1/events" (t : @test.Test) {
  @mock.run(t, mock => {
    let group = mock.group
    let server = configure_server(mock)
    group.spawn_bg(() => server.start(), no_wait=true)
    let collector = group.spawn(() => {
      let (r, s) = @http.get_stream(
        "http://localhost:\{server.port()}/v1/events",
      )
      json_inspect(r.code, content=200)
      @test_utils.ServerEvent::collect_events(s)
    })
    let (_, b) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/message",
      { "message": { "role": "user", "content": "Hello, Maria!" } },
    )
    let b = b.json()
    guard b is { "id": String(msg0_id), .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    let (_, b) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/message",
      { "message": { "role": "user", "content": "Hello again, Maria!" } },
    )
    let b = b.json()
    guard b is { "id": String(msg1_id), .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    let events = collector.wait()
    json_inspect(
      @test_utils.redact_events(
        @test_utils.extract_events_for_message(
          events,
          id=msg0_id,
          content="Hello, Maria!",
        ),
      ),
      content=[
        [
          "Maria",
          {
            "id": "00000000-0000-0000-0000-000000000000",
            "created": 0,
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
            "created": 0,
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
            "created": 0,
            "desc": { "msg": "UserMessage", "content": "<redacted>" },
          },
        ],
      ],
    )
    json_inspect(
      @test_utils.redact_events(
        @test_utils.extract_events_for_message(
          events,
          id=msg1_id,
          content="Hello again, Maria!",
        ),
      ),
      content=[
        [
          "Maria",
          {
            "id": "00000000-0000-0000-0000-000000000000",
            "created": 0,
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
            "created": 0,
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
            "created": 0,
            "desc": { "msg": "UserMessage", "content": "<redacted>" },
          },
        ],
      ],
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
    json_inspect(r.code, content=204)
    json_inspect(r.headers["access-control-allow-origin"], content="*")
    json_inspect(r.headers["access-control-allow-methods"], content="*")
    json_inspect(r.headers["access-control-allow-headers"], content="*")
  })
}

///|
async test "GET /" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_file("index.html").write_string("<h1>Home Page</h1>")
    let server = configure_server(mock, serve=mock.cwd.path())
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/")
    json_inspect(r.code, content=200)
    json_inspect(r.headers["content-type"], content="text/html")
    json_inspect(b.text(), content="<h1>Home Page</h1>")
  })
}

///|
async test "GET /script.js" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_file("script.js").write_string("console.log('Hello, world!');")
    let server = configure_server(mock, serve=mock.cwd.path())
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/script.js")
    json_inspect(r.code, content=200)
    json_inspect(r.headers["content-type"], content="application/javascript")
    json_inspect(b.text(), content="console.log('Hello, world!');")
  })
}

///|
#skip
async test "POST /v1/cancel" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    @async.with_task_group(group => {
      group.spawn_bg(() => server.start(), no_wait=true)
      let collector = group.spawn(() => {
        let (r, s) = @http.get_stream(
          "http://localhost:\{server.port()}/v1/events",
        )
        json_inspect(r.code, content=200)
        @test_utils.ServerEvent::collect_events(s)
      })
      let (r, b) = @http.get("http://localhost:\{server.port()}/v1/status")
      json_inspect(r.code, content=200)
      json_inspect(b.json(), content={ "status": "idle", "web_search": false })
      let (r, b) = @httpx.post_json(
        "http://localhost:\{server.port()}/v1/message",
        { "message": { "role": "user", "content": "Hello, Maria!" } },
      )
      json_inspect(r.code, content=200)
      let b = b.json()
      guard b is { "id": String(_), "queued": false, .. } else {
        fail("Invalid response body: \{b.stringify(indent=2)}")
      }
      let (_, b) = @httpx.post_json(
        "http://localhost:\{server.port()}/v1/message",
        {
          "message": {
            "role": "user",
            "content": "This message will be popped on cancellation",
          },
        },
      )
      let b = b.json()
      guard b is { "id": String(id), "queued": true, .. } else {
        fail("Invalid response body: \{b.stringify(indent=2)}")
      }
      let (r, b) = @httpx.post_json(
        "http://localhost:\{server.port()}/v1/cancel",
        {},
      )
      json_inspect(r.code, content=200)
      json_inspect(b.json(), content={
        "pending_messages": [
          {
            "id": id,
            "message": {
              "role": "user",
              "content": "This message will be popped on cancellation",
            },
            "web_search": false,
          },
        ],
      })
      let events = collector.wait()
      // There is no MessageAdded event for the cancelled message
      json_inspect(
        events
        .filter(e => {
          e is Maria(event) &&
          event.desc is UserMessage(msg) &&
          msg == "This message will be popped on cancellation"
        })
        .length(),
        content=0,
      )
      // There is a MariaCancelled event
      json_inspect(
        events.filter(e => e is Maria(event) && event.desc is Cancelled)
        |> @test_utils.redact_events(),
        content=[
          [
            "Maria",
            {
              "id": "00000000-0000-0000-0000-000000000000",
              "created": 0,
              "desc": { "msg": "Cancelled" },
            },
          ],
        ],
      )
      // Should be able to send another message after cancellation
      let _ = @httpx.post_json("http://localhost:\{server.port()}/v1/message", {
        "message": { "role": "user", "content": "Hello again, Maria!" },
      })
      let (r, s) = @http.get_stream(
        "http://localhost:\{server.port()}/v1/events",
      )
      json_inspect(r.code, content=200)
      // We want skip over the first cancellation event.
      @test_utils.ServerEvent::collect_events(s, stop_at_cancel=false)
      |> ignore()
    })
  })
}

///|
#skip
#cfg(false)
async test "web_search" (t : @test.Test) {
  @mock.run(t, mock => {
    let group = mock.group
    let server = configure_server(mock)
    group.spawn_bg(() => server.start(), no_wait=true)
    let collector = group.spawn(() => {
      let (r, s) = @http.get_stream(
        "http://localhost:\{server.port()}/v1/events",
      )
      json_inspect(r.code, content=200)
      @test_utils.ServerEvent::collect_events(s)
    })
    let _ = @httpx.post_json("http://localhost:\{server.port()}/v1/message", {
      "message": {
        "role": "user",
        "content": "Can you please search the web for MoonBit to find out which year it is initiated?",
      },
      "web_search": true,
    })
    let events = collector.wait()
    json_inspect(
      events
      .filter(e => {
        e is @test_utils.Maria(event) &&
        event.desc is AssistantMessage(content, ..) &&
        (content.contains("2022") || content.contains("2023"))
      })
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
    json_inspect(r.code, content=200)
    let b = b.json()
    json_inspect(b, content={
      "execute_command": { "enabled": true },
      "list_files": { "enabled": true },
      "read_file": { "enabled": true },
      "todo": { "enabled": true },
      "search_files": { "enabled": true },
      "write_to_file": { "enabled": true },
    })
    let (r, b) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/enabled-tools",
      ["list_files", "read_file", "todo", "search_files", "write_to_file"],
    )
    json_inspect(r.code, content=200)
    json_inspect(b.json(), content={})
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/tools")
    json_inspect(r.code, content=200)
    let b = b.json()
    json_inspect(b, content={
      "execute_command": { "enabled": false },
      "list_files": { "enabled": true },
      "read_file": { "enabled": true },
      "todo": { "enabled": true },
      "search_files": { "enabled": true },
      "write_to_file": { "enabled": true },
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
    json_inspect(r.code, content=200)
    let b = b.json()
    json_inspect(b is String(text) && text.length() > 0, content=true)
    let (r, b) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/system-prompt",
      "New system prompt.",
    )
    json_inspect(r.code, content=200)
    json_inspect(b.json(), content={})
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/system-prompt")
    json_inspect(r.code, content=200)
    let b = b.json()
    json_inspect(r.code, content=200)
    json_inspect(b, content="New system prompt.")
  })
}

///|
#skip
async test "GET /v1/external-event/user-message" (t : @test.Test) {
  @mock.run(t, mock => {
    let server = configure_server(mock)
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/status")
    json_inspect(r.code, content=200)
    json_inspect(b.json(), content={ "status": "idle", "web_search": false })
    let (r, b) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/external-event/user-message",
      { "message": "Hello, Maria!" },
    )
    json_inspect(r.code, content=200)
    json_inspect(b.json(), content={ "success": true })
    let (r, b) = @http.get(
      "http://localhost:\{server.port()}/v1/queued-messages",
    )
    json_inspect(r.code, content=200)
    let b = b.json()
    json_inspect(b, content=[])
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
      json_inspect(r.code, content=200)
      @test_utils.ServerEvent::collect_events(s)
    })
    let (r, b) = @http.get("http://localhost:\{server.port()}/v1/status")
    json_inspect(r.code, content=200)
    json_inspect(b.json(), content={ "status": "idle", "web_search": false })
    let (r, b) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/message",
      {
        "message": {
          "role": "user",
          "content": "Can you please tell me when is it now by spawning the 'date' command?",
        },
      },
    )
    json_inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(_), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    json_inspect(queued, content=false)
    let (r, b) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/message",
      {
        "message": {
          "role": "user",
          "content": "Can you please tell me what is the current weather in New York?",
        },
      },
    )
    json_inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(_), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    json_inspect(queued, content=true)
    let (r, _) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/external-event/cancel",
      {},
    )
    json_inspect(r.code, content=200)
    let events = collector.wait()
    json_inspect(
      events
      .filter(e => e is Maria(event) && event.desc is MessageUnqueued(_))
      .length(),
      content=1,
    )
    json_inspect(
      events.filter(e => e is Maria(event) && event.desc is Cancelled).length(),
      content=1,
    )
  })
}
