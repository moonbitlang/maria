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
