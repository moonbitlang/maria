///|
async test "event-stream" (t : @test.Test) {
  @mock.run(t, _ => {
    let s = @httpx.Server::new("[::1]", 0)
    @async.with_task_group(g => {
      g.spawn_bg(
        () => s.serve((_, w) => {
          let w = @httpx.EventStreamWriter::new(w)
          w.write_header(@status.Ok)
          for i in 0..<3 {
            w.write_event(
              id=i.to_string(),
              event="message",
              data=Json::object({ "count": i }),
            )
          }
        }),
        no_wait=true,
      )
      let c = @http.Client::connect("localhost", protocol=Http, port=s.port())
      defer c.close()
      c.request(Get, "/")
      let r = c.end_request()
      @json.inspect(r.code, content=200)
      @json.inspect(r.reason, content="OK")
      @json.inspect(r.headers.get("content-type"), content=["text/event-stream"])
      inspect(
        c.read_all().text(),
        content=(
          #|event: message
          #|data: {"count":0}
          #|id: 0
          #|
          #|event: message
          #|data: {"count":1}
          #|id: 1
          #|
          #|event: message
          #|data: {"count":2}
          #|id: 2
          #|
          #|
        ),
      )
    })
  })
}
