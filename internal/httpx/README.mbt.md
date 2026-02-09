# HTTPX Package

The `httpx` package provides a small, composable HTTP toolkit for building
servers on top of `@http.Server`. It includes:

- A lightweight `RequestReader`/`ResponseWriter` pair
- A method- and path-based router
- JSON request/response helpers
- Static file serving
- CORS and Server-Sent Events (SSE) helpers

## Quick Start

### Minimal JSON API Server

The following example shows how to expose a simple JSON endpoint using
`Router`, `JsonRequestReader`, and `JsonResponseWriter`:

```moonbit check
///|
struct ExampleRequest {
  name : String
  description : String
} derive(ToJson, @json.FromJson)
```

```moonbit check
///|
enum ExampleResponse {
  Ok(ExampleRequest)
} derive(ToJson)
```

```mbt check
///|
async test "Minimal JSON API Server" {
  let router = @httpx.Router::new()

  // Register a POST /task handler that reads and writes JSON
  router.add_handler(Post, "/task", (r, w) => {
    let r = @httpx.JsonRequestReader::new(r)
    let w = @httpx.JsonResponseWriter::new(w)
    let task : ExampleRequest = r.read()
    w.write_header(@status.Ok)
    let res = ExampleResponse::Ok(task)
    w.write(res)
  })

  // Start the HTTP server with the router
  let server = @httpx.Server::new("[::1]", 0)

  // Tests to verify the /task endpoint
  @async.with_task_group(group => {
    // Start the server with CORS enabled
    group.spawn_bg(no_wait=true, () => {
      server.serve(@httpx.cors(router.handler()))
    })
    let (r, b) = @httpx.post_json("http://localhost:\{server.port()}/task", {
      "name": "Example Task",
      "description": "This is an example task.",
    })
    guard r.code is @status.Ok else {
      fail("Unexpected response code: \{r.code}")
    }
    json_inspect(b.json(), content=[
      "Ok",
      { "name": "Example Task", "description": "This is an example task." },
    ])
  })
}
```

### Router and File Server

You can combine the router with `FileServer` to serve static files and dynamic
routes from the same HTTP server:

```mbt check
///|
async test "Router and File Server" {
  let file_server = @httpx.FileServer::new("cmd/server")

  // Fallback to file server when no route matches
  let router = @httpx.Router::new()
  router.add_handler(Get, "/hello", (_, w) => {
    w.write_header(@status.Ok)
    w.write("Hello, world! from Router Handler\n")
  })
  router.set_not_found_handler((r, w) => file_server.handle(r, w))
  let server = @httpx.Server::new("[::1]", 0)

  // Start the server and test both the dynamic route and static file serving
  @async.with_task_group(group => {
    group.spawn_bg(() => server.serve(router.handler()), no_wait=true)
    let (r, b) = @http.get("http://localhost:\{server.port()}/hello")
    guard r.code is @status.Ok else {
      fail("Unexpected response code: \{r.code}")
    }
    guard b.text() is "Hello, world! from Router Handler\n" else {
      fail("Unexpected response body: \{b.text()}")
    }
    let (r, _) = @http.get("http://localhost:\{server.port()}/")
    guard r.code is @status.Ok else {
      fail("Unexpected response code: \{r.code}")
    }
  })
}
```

### Enabling CORS

The `cors` middleware adds permissive CORS headers to all responses:

```mbt check
///|
async test "CORS Middleware" {
  let file_server = @httpx.FileServer::new("cmd/server")
  let router = @httpx.Router::new()
  router.add_handler(Get, "/hello", (_, w) => {
    w.write_header(@status.Ok)
    w.write("Hello, world! from Router Handler\n")
  })
  router.set_not_found_handler((r, w) => file_server.handle(r, w))
  let server = @httpx.Server::new("[::1]", 0)
  @async.with_task_group(group => {
    group.spawn_bg(no_wait=true, () => {
      server.serve(@httpx.cors(router.handler()))
    })
    let (r, b) = @http.get("http://localhost:\{server.port()}/hello")
    guard r.code is @status.Ok else {
      fail("Unexpected response code: \{r.code}")
    }
    guard r.headers
      is {
        "access-control-allow-origin": "*",
        "access-control-allow-methods": "*",
        "access-control-allow-headers": "*",
        ..
      } else {
      fail("CORS headers missing or incorrect")
    }
    guard b.text() is "Hello, world! from Router Handler\n" else {
      fail("Unexpected response body: \{b.text()}")
    }
  })
}
```
