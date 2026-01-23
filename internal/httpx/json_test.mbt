///|
struct TaskRequest {
  name : String
  description : String
} derive(ToJson, @json.FromJson)

///|
enum TaskResponse {
  Ok(TaskRequest)
} derive(ToJson)

///|
async test "JsonRequestReader" (t : @test.Test) {
  @mock.run(t, _ => {
    let router = @httpx.Router::new()
    router.add_handler(Post, "/task", (r, w) => {
      let r = @httpx.JsonRequestReader::new(r)
      let w = @httpx.JsonResponseWriter::new(w)
      let task : TaskRequest = r.read()
      w.write_header(200)
      let res = TaskResponse::Ok(task)
      w.write(res)
    })
    let server = @httpx.Server::new("[::1]", 0)
    @async.with_task_group(group => {
      group.spawn_bg(
        () => server.serve(@httpx.cors(router.handler())),
        no_wait=true,
      )
      let (r, b) = post_json("http://localhost:\{server.port()}/task", {
        "name": "Example Task",
        "description": "This is an example task.",
      })
      json_inspect(r.code, content=200)
      json_inspect(b.json(), content=[
        "Ok",
        { "name": "Example Task", "description": "This is an example task." },
      ])
      let (r, b) = @http.post(
        "http://localhost:\{server.port()}/task",
        b"\xFF\xFF",
      )
      json_inspect(r.code, content=400)
      json_inspect(b.json(), content={
        "error": {
          "code": 400,
          "message": "Invalid UTF-8 in request body",
          "data": "moonbitlang/core/encoding/utf8.Malformed.Malformed",
        },
      })
      let (r, b) = @http.post(
        "http://localhost:\{server.port()}/task",
        b"{ invalid json }",
      )
      json_inspect(r.code, content=400)
      json_inspect(b.json(), content={
        "error": {
          "code": 400,
          "message": "Invalid JSON in request body",
          "data": ["InvalidChar", { "line": 1, "column": 2 }, "i"],
        },
      })
      let (r, b) = post_json("http://localhost:\{server.port()}/task", {
        "name": "Incomplete Task",
      })
      json_inspect(r.code, content=400)
      json_inspect(b.json(), content={
        "error": {
          "code": 400,
          "message": "Invalid request body",
          "data": ["JsonDecodeError", ["", "Missing field description"]],
        },
      })
    })
  })
}
