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

```moonbit test(async)
///|
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
  group.spawn_bg(
    () => server.serve(@httpx.cors(router.handler())),
    no_wait=true,
  )
  let (r, b) = @httpx.post_json("http://localhost:\{server.port()}/task", {
    "name": "Example Task",
    "description": "This is an example task.",
  })
  @json.inspect(r.code, content=@status.Ok.to_json())
  @json.inspect(b.json(), content=[
    "Ok",
    { "name": "Example Task", "description": "This is an example task." },
  ])
})
```

### Router and File Server

You can combine the router with `FileServer` to serve static files and dynamic
routes from the same HTTP server:

```moonbit test(async)
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
  @json.inspect(r.code, content=@status.Ok.to_json())
  @json.inspect(b.text(), content="Hello, world! from Router Handler\n")
  let (r, _) = @http.get("http://localhost:\{server.port()}/")
  @json.inspect(r.code, content=@status.Ok.to_json())
})
```

### Enabling CORS

The `cors` middleware adds permissive CORS headers to all responses:

```moonbit test(async)
let file_server = @httpx.FileServer::new("cmd/server")
let router = @httpx.Router::new()
router.add_handler(Get, "/hello", (_, w) => {
  w.write_header(@status.Ok)
  w.write("Hello, world! from Router Handler\n")
})
router.set_not_found_handler((r, w) => file_server.handle(r, w))
let server = @httpx.Server::new("[::1]", 0)
@async.with_task_group(group => {
  group.spawn_bg(
    () => server.serve(@httpx.cors(router.handler())),
    no_wait=true,
  )
  let (r, b) = @http.get("http://localhost:\{server.port()}/hello")
  @json.inspect(r.code, content=@status.Ok.to_json())
  @json.inspect(r.headers["access-control-allow-origin"], content="*")
  @json.inspect(r.headers["access-control-allow-methods"], content="*")
  @json.inspect(r.headers["access-control-allow-headers"], content="*")
  @json.inspect(b.text(), content="Hello, world! from Router Handler\n")
})
```
