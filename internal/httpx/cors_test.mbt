///|
async test "@moonbitlang/maria/internal/httpx.cors" {
  let router = @httpx.Router::new()
  router.add_handler(Post, "/task", (_, w) => {
    w.write_header(@status.Ok)
    w.write("Hello, world! from Post Handler\n")
  })
  router.add_handler(Get, "/tasks", (_, w) => {
    w.write_header(@status.Ok)
    w.write("Hello, world! from Tasks Handler\n")
  })
  router.add_handler(Get, "/task/{id}", (r, w) => {
    let id = r.vars["id"]
    w.write_header(@status.Ok)
    w.write("Hello, world! from Task \{id} Handler\n")
  })
  let server = @httpx.Server::new("[::1]", 0)
  @async.with_task_group(group => {
    group.spawn_bg(
      () => server.serve(@httpx.cors((r, w) => router.handle(r, w))),
      no_wait=true,
    )
    let client = @http.Client::connect(
      "localhost",
      protocol=Http,
      port=server.port(),
    )
    client.request(Options, "*")
    let response = client.end_request()
    @json.inspect(response.code, content=204)
    @json.inspect(response.reason, content="No Content")
    @json.inspect(response.headers, content={
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "*",
      "access-control-allow-headers": "*",
      "transfer-encoding": "chunked",
    })
    let client = @http.Client::connect(
      "localhost",
      protocol=Http,
      port=server.port(),
    )
    client.request(Options, "/task")
    let response = client.end_request()
    @json.inspect(response.code, content=204)
    @json.inspect(response.reason, content="No Content")
    @json.inspect(response.headers, content={
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "*",
      "access-control-allow-headers": "*",
      "transfer-encoding": "chunked",
    })
    let client = @http.Client::connect(
      "localhost",
      protocol=Http,
      port=server.port(),
    )
    client.request(Options, "/tasks")
    let response = client.end_request()
    @json.inspect(response.code, content=204)
    @json.inspect(response.reason, content="No Content")
    @json.inspect(response.headers, content={
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "*",
      "access-control-allow-headers": "*",
      "transfer-encoding": "chunked",
    })
    let (response, body) = @http.get(
      "http://localhost/task/42",
      port=server.port(),
    )
    @json.inspect(response.code, content=200)
    @json.inspect(response.reason, content="OK")
    @json.inspect(body.text(), content="Hello, world! from Task 42 Handler\n")
    let (response, body) = @http.get(
      "http://localhost/task/100",
      port=server.port(),
    )
    @json.inspect(response.code, content=200)
    @json.inspect(response.reason, content="OK")
    @json.inspect(body.text(), content="Hello, world! from Task 100 Handler\n")
  })
}
