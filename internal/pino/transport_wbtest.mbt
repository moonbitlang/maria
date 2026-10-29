///|
async test "Transport::Channel" {
  let channel = @aqueue.Queue(kind=Unbounded)
  let transport = Transport::channel(channel)
  transport.write(Json::string("test message"))
  json_inspect(channel.try_get(), content=["test message"])
}

///|
async test "Transport::callback" {
  let logs = []
  let f = message => logs.push(message)
  let transport = Transport::callback(f)
  transport.write(Json::string("callback message"))
  json_inspect(logs, content=["callback message"])
}

///|
async test "Transport::parse" {
  json_inspect(Transport::parse("console:") is Console, content=true)
  json_inspect(
    Transport::parse("file:/tmp/log.txt") is File(path="/tmp/log.txt", ..),
    content=true,
  )
  json_inspect(
    (Ok(Transport::parse("channel:")) catch { error => Err(error) }) is Err(_),
    content=true,
  )
}

///|
async test "file transport serializes concurrent writes" {
  let path = @os.tmpdir() +
    "/maria-pino-concurrent-" +
    @spawn.getpid().to_string() +
    ".jsonl"
  let transport = Transport::file(path)
  defer {
    transport.close()
    @fs.remove(path) catch {
      _ => ()
    }
  }
  @async.with_task_group(group => {
    for i in 0..<100 {
      group.spawn_bg(() => transport.write({ "index": i }))
    }
  })
  transport.close()
  let text = @fs.read_file(path).text()
  let lines = text.trim_end().split("\n").to_array()
  assert_eq(lines.length(), 100)
  let seen = Map([])
  for line in lines {
    let json = @json.parse(line)
    guard json is { "index": Number(index, ..), .. } else {
      fail("Invalid log record")
    }
    seen[index] = true
  }
  assert_eq(seen.length(), 100)
}
