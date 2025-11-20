///|
async test "FileServer" (t : @test.Test) {
  @mock.run(t, mock => {
    mock
    .add_file("index.html")
    .write_string(
      (
        #|<html>
        #|  <head>
        #|    <title>Test File Server</title>
        #|  </head>
        #|  <body>
        #|    <h1>Welcome to the Test File Server</h1>
        #|  </body>
        #|</html>
      ),
    )
    mock
    .add_file("style.css")
    .write_string("body { background-color: #f0f0f0; }")
    mock.add_file("script.js").write_string("console.log('Hello, World!');")
    let f = FileServer::new(mock.cwd.path())
    let s = Server::new("[::1]", 0)
    mock.group.spawn_bg(() => s.serve((r, w) => f.handle(r, w)), no_wait=true)
    let (r, b) = @http.get("http://localhost", port=s.port())
    @json.inspect(r.code, content=200)
    @json.inspect(r.headers["content-type"], content="text/html")
    inspect(
      b.text(),
      content=(
        #|<html>
        #|  <head>
        #|    <title>Test File Server</title>
        #|  </head>
        #|  <body>
        #|    <h1>Welcome to the Test File Server</h1>
        #|  </body>
        #|</html>
      ),
    )
    let (r, b) = @http.get("http://localhost/style.css", port=s.port())
    @json.inspect(r.code, content=200)
    @json.inspect(r.headers["content-type"], content="text/css")
    inspect(b.text(), content="body { background-color: #f0f0f0; }")
    let (r, b) = @http.get("http://localhost/script.js", port=s.port())
    @json.inspect(r.code, content=200)
    @json.inspect(r.headers["content-type"], content="application/javascript")
    inspect(b.text(), content="console.log('Hello, World!');")
    let (r, _) = @http.get("http://localhost/nonexistent", port=s.port())
    @json.inspect(r.code, content=404)
  })
}

///|
async test "Router+FileServer" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_file("index.html").write_string("<h1>Home Page</h1>")
    let f = FileServer::new(mock.cwd.path())
    f.set_not_found_handler((_, w) => {
      w.write_header(@status.NotFound)
      w.write("<h1>Custom 404 Not Found</h1>")
    })
    let mux = Router::new()
    mux.add_handler(Get, "/hello", (_, w) => {
      w.write_header(@status.Ok)
      w.write("Hello, world! from Router Handler\n")
    })
    mux.set_not_found_handler((r, w) => f.handle(r, w))
    let s = Server::new("[::1]", 0)
    mock.group.spawn_bg(() => s.serve(mux.handler()), no_wait=true)
    let (r, b) = @http.get("http://localhost/hello", port=s.port())
    @json.inspect(r.code, content=200)
    @json.inspect(b.text(), content="Hello, world! from Router Handler\n")
    let (r, b) = @http.get("http://localhost/", port=s.port())
    @json.inspect(r.code, content=200)
    @json.inspect(b.text(), content="<h1>Home Page</h1>")
    let (r, b) = @http.get("http://localhost/notfound", port=s.port())
    @json.inspect(r.code, content=404)
    inspect(b.text(), content="<h1>Custom 404 Not Found</h1>")
  })
}

///|
async test "FileServer+Router" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_file("index.html").write_string("<h1>Home Page</h1>")
    let f = FileServer::new(mock.cwd.path())
    let mux = Router::new()
    mux.add_handler(Get, "/hello", (_, w) => {
      w.write_header(@status.Ok)
      w.write("Hello, world! from Router Handler\n")
    })
    mux.set_not_found_handler((_, w) => {
      w.write_header(@status.NotFound)
      w.write("404 Not Found from Router\n")
    })
    f.set_not_found_handler(mux.handler())
    let s = Server::new("[::1]", 0)
    mock.group.spawn_bg(() => s.serve(f.handler()), no_wait=true)
    let (r, b) = @http.get("http://localhost/hello", port=s.port())
    @json.inspect(r.code, content=200)
    @json.inspect(b.text(), content="Hello, world! from Router Handler\n")
    let (r, b) = @http.get("http://localhost/", port=s.port())
    @json.inspect(r.code, content=200)
    @json.inspect(b.text(), content="<h1>Home Page</h1>")
    let (r, b) = @http.get("http://localhost/notfound", port=s.port())
    @json.inspect(r.code, content=404)
    inspect(
      b.text(),
      content=(
        #|404 Not Found from Router
        #|
      ),
    )
  })
}

///|
async test "CORS+Router+FileServer" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_file("index.html").write_string("<h1>Home Page</h1>")
    let f = FileServer::new(mock.cwd.path())
    let mux = Router::new()
    mux.add_handler(Get, "/hello", (_, w) => {
      w.write_header(@status.Ok)
      w.write("Hello, world! from Router Handler\n")
    })
    mux.set_not_found_handler((r, w) => f.handle(r, w))
    let s = Server::new("[::1]", 0)
    mock.group.spawn_bg(() => s.serve(@httpx.cors(mux.handler())), no_wait=true)
    let (r, b) = @http.get("http://localhost/hello", port=s.port())
    @json.inspect(r.code, content=200)
    @json.inspect(r.headers["access-control-allow-origin"], content="*")
    @json.inspect(r.headers["access-control-allow-methods"], content="*")
    @json.inspect(r.headers["access-control-allow-headers"], content="*")
    @json.inspect(b.text(), content="Hello, world! from Router Handler\n")
    let (r, b) = @http.get("http://localhost/", port=s.port())
    @json.inspect(r.code, content=200)
    @json.inspect(b.text(), content="<h1>Home Page</h1>")
    @json.inspect(r.headers["access-control-allow-origin"], content="*")
    @json.inspect(r.headers["access-control-allow-methods"], content="*")
    @json.inspect(r.headers["access-control-allow-headers"], content="*")
  })
}
