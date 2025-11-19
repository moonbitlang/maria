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
async fn configure_server(mock : @mock.Context, register? : Register) -> Server {
  configure_models(mock)
  Server::new(
    model="mock:claude-haiku-4.5",
    log_level=Info,
    serve=mock.cwd.path(),
    register?,
    port=0,
    cwd=mock.cwd.path(),
  )
}

///|
async test "register" (t : @test.Test) {
  @mock.run(t, mock => {
    let addr = @socket.Addr::parse("[::]:0")
    let daemon = @socket.TcpServer::new(addr, dual_stack=true, reuse_addr=true)
    defer daemon.close()
    let server : Server = configure_server(mock, register=Register::{
      host: "localhost",
      port: daemon.addr().port(),
      id: "test-server",
    })
    mock.group.spawn_bg(() => server.serve(), no_wait=true)
    let (conn, _) = daemon.accept()
    let conn = @http.ServerConnection::new(conn)
    let r = conn.read_request()
    guard r.path is "/v1/task/register" else { return }
    let rb = conn.read_all()
    @json.inspect(rb.json(), content={
      "id": "test-server",
      "port": server.port,
    })
  })
}

///|
async test "POST /v1/message" (t : @test.Test) {
  @mock.run(t, mock => {
    let server : Server = configure_server(mock)
    mock.group.spawn_bg(() => server.serve(), no_wait=true)
    let (r, b) = @http.post(
      "http://localhost/v1/message",
      Json::object({ "message": { "role": "user", "content": "Hello, Maria!" } }),
      port=server.port,
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(_), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    @json.inspect(queued, content=false)
    let (r, b) = @http.post(
      "http://localhost/v1/message",
      Json::object({ "message": { "role": "user", "content": "Hello again!" } }),
      port=server.port,
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    guard b is { "id": String(qid), "queued": queued, .. } else {
      fail("Invalid response body: \{b.stringify(indent=2)}")
    }
    @json.inspect(queued, content=true)
    let (r, b) = @http.get(
      "http://localhost/v1/queued-messages",
      port=server.port,
    )
    @json.inspect(r.code, content=200)
    let b = b.json()
    @json.inspect(b, content=[
      { "id": qid, "message": { "role": "user", "content": "Hello again!" } },
    ])
  })
}
