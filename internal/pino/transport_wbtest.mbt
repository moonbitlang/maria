///|
async test "Transport::Channel" {
  let channel = @aqueue.new(kind=Unbounded)
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
  json_inspect((try? Transport::parse("channel:")) is Err(_), content=true)
}
