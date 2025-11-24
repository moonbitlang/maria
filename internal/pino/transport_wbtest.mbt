///|
async test "Transport::Channel" {
  let channel = @aqueue.new(kind=Unbounded)
  let transport = Transport::channel(channel)
  (transport.write)(Entry::{
    level: Info,
    msg: "test message",
    data: {},
    pid: 0,
    hostname: None,
    time: 0,
  })
  @json.inspect(channel.try_get(), content=["test message"])
}

///|
async test "Transport::callback" {
  let logs = []
  let f = message => logs.push(message)
  let transport = Transport::callback(f)
  (transport.write)(Entry::{
    level: Info,
    msg: "callback message",
    data: {},
    pid: 0,
    hostname: None,
    time: 0,
  })
  @json.inspect(logs, content=["callback message"])
}

///|
async test "Transport::parse" {
  @json.inspect(Transport::parse("console:") is Console, content=true)
  @json.inspect(
    Transport::parse("file:/tmp/log.txt") is File(path="/tmp/log.txt", ..),
    content=true,
  )
  @json.inspect((try? Transport::parse("channel:")) is Err(_), content=true)
}
