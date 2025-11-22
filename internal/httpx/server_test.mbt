///|
async test "@moonbitlang/maria/internal/httpx.Server" {
  let router = @httpx.Router::new()
  router.add_handler(Post, "/hello", (_, w) => {
    w.write_header(@status.Ok)
    w.write("Hello, world! from Post Handler\n")
  })
  router.add_handler(Get, "/hello", (_, w) => {
    w.write_header(@status.Ok)
    w.write("Hello, world! from Get Handler\n")
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
    group.spawn_bg(() => server.serve(router.handler()), no_wait=true)
    let (r, b) = @http.post("http://localhost/hello", "", port=server.port())
    @json.inspect(r.code, content=200)
    @json.inspect(r.reason, content="OK")
    @json.inspect(b.text(), content="Hello, world! from Post Handler\n")
    let (r, body) = @http.get("http://localhost/hello", port=server.port())
    @json.inspect(r.code, content=200)
    @json.inspect(r.reason, content="OK")
    @json.inspect(body.text(), content="Hello, world! from Get Handler\n")
    let (r, body) = @http.get("http://localhost/notfound", port=server.port())
    @json.inspect(r.code, content=404)
    @json.inspect(r.reason, content="Not Found")
    @json.inspect(body.text(), content="")
    let c = @http.Client::connect(
      "localhost",
      protocol=Http,
      port=server.port(),
    )
    defer c.close()
    c.request(Options, "*")
    let r = c.end_request()
    @json.inspect(r.code, content=204)
    @json.inspect(r.reason, content="No Content")
    @json.inspect(r.headers["allow"], content="GET, POST")
    let c = @http.Client::connect(
      "localhost",
      protocol=Http,
      port=server.port(),
    )
    defer c.close()
    c.request(Options, "/hello")
    let r = c.end_request()
    @json.inspect(r.code, content=405)
    @json.inspect(r.reason, content="Method Not Allowed")
    @json.inspect(r.headers["allow"], content="GET, POST")
    let client = @http.Client::connect(
      "localhost",
      protocol=Http,
      port=server.port(),
    )
    client.request(Options, "/tasks")
    let r = client.end_request()
    @json.inspect(r.code, content=405)
    @json.inspect(r.reason, content="Method Not Allowed")
    @json.inspect(r.headers["allow"], content="GET")
    let (r, b) = @http.get("http://localhost/task/42", port=server.port())
    @json.inspect(r.code, content=200)
    @json.inspect(r.reason, content="OK")
    @json.inspect(b.text(), content="Hello, world! from Task 42 Handler\n")
    let (r, b) = @http.get("http://localhost/task/100", port=server.port())
    @json.inspect(r.code, content=200)
    @json.inspect(r.reason, content="OK")
    @json.inspect(b.text(), content="Hello, world! from Task 100 Handler\n")
  })
}

///|
async test "Connection: keep-alive" {
  let server = @httpx.Server::new("[::1]", 0)
  @async.with_task_group(group => {
    group.spawn_bg(
      () => server.serve((_, w) => {
        w.write_header(@status.Ok)
        w.write("Hello, world!\n")
      }),
      no_wait=true,
    )
    @async.pause()
    let client = @http.Client::connect(
      "localhost",
      protocol=Http,
      headers={ "Connection": "keep-alive" },
      port=server.port(),
    )
    defer client.close()
    client.request(Get, "/hello")
    let r = client.end_request()
    @json.inspect(r.code, content=200)
    @json.inspect(r.reason, content="OK")
    let b = client.read_all()
    @json.inspect(b.text(), content="Hello, world!\n")
    @json.inspect(
      try? {
        client.request(Get, "/hello")
        let r = client.end_request()
        { "code": r.code.to_json(), "body": client.read_all().text().to_json() }
      },
      content={ "Ok": { "code": 200, "body": "Hello, world!\n" } },
    )
  })
}

///|
async test "Connection: close" {
  let server = @httpx.Server::new("[::1]", 0)
  @async.with_task_group(group => {
    group.spawn_bg(
      () => server.serve((_, w) => {
        w.write_header(@status.Ok)
        w.write("Hello, world!\n")
      }),
      no_wait=true,
    )
    @async.pause()
    let client = @http.Client::connect(
      "localhost",
      protocol=Http,
      headers={ "Connection": "close" },
      port=server.port(),
    )
    defer client.close()
    client.request(Get, "/hello")
    let r = client.end_request()
    @json.inspect(r.code, content=200)
    @json.inspect(r.reason, content="OK")
    let b = client.read_all()
    @json.inspect(b.text(), content="Hello, world!\n")
    @json.inspect(
      try? {
        client.request(Get, "/hello")
        let r = client.end_request()
        { "code": r.code.to_json(), "body": client.read_all().text().to_json() }
      },
      content={ "Err": "moonbitlang/async/io.ReaderClosed.ReaderClosed" },
    )
  })
}
