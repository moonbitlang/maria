///|
async test "cancel broadcasts to SSE with an offline provider" (t : @test.Test) {
  @mock.run(t, timeout=10_000, mock => {
    let provider = @httpx.Server::new("[::1]", 0)
    let requested : @aqueue.Queue[Unit] = @aqueue.Queue(kind=Unbounded)
    mock.group.spawn_bg(
      () => {
        provider.serve((_, _) => {
          requested.put(())
          // Keep the model request pending until the API cancels it.
          @async.sleep(60_000)
        })
      },
      no_wait=true,
    )
    let models : Json = [
      {
        "name": "offline:pending",
        "description": "Local cancellation fixture",
        "model_name": "pending",
        "model_type": "saas/openai",
        "base_url": "http://localhost:\{provider.port()}/v1",
        "is_reasoning": false,
        "input_price": 0,
        "output_price": 0,
        "average_speed": 0,
        "safe_zone_tokens": 128000,
        "max_output_tokens": 1024,
        "api_key": "offline-fixture",
        "supports_anthropic_prompt_caching": false,
      },
    ]
    mock.cwd.add_json_tree({
      ".moonagent": { "models": { "models.json": models.stringify() } },
    })
    let server = @server.Server::new(
      model="offline:pending",
      serve=mock.cwd.path(),
      home=mock.cwd.path(),
      cwd=mock.cwd.path(),
      port=0,
    )
    mock.group.spawn_bg(() => server.start(), no_wait=true)
    let events = mock.group.spawn(() => {
      let (_, stream) = @http.get_stream(
        "http://localhost:\{server.port()}/v1/events",
      )
      @test_utils.ServerEvent::collect_events(stream)
    })
    let (response, _) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/message",
      { "message": { "role": "user", "content": "Wait for cancellation" } },
    )
    assert_eq(response.code, 200)
    requested.get()
    let (response, body) = @httpx.post_json(
      "http://localhost:\{server.port()}/v1/cancel",
      {},
    )
    assert_eq(response.code, 200)
    json_inspect(body.json(), content={ "pending_messages": [] })
    assert_eq(
      events
      .wait()
      .filter(event => event is Maria({ desc: Cancelled, .. }))
      .length(),
      1,
    )
  })
}
