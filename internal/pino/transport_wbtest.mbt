///|
async test "Transport::Channel" {
  let channel = @aqueue.new()
  let transport = Transport::channel(channel)
  transport.write(Json::string("test message"))
  @json.inspect(channel.try_get(), content=["test message"])
}

///|
async test "Transport::callback" {
  let logs = []
  let f = message => logs.push(message)
  let transport = Transport::callback(f)
  transport.write(Json::string("callback message"))
  @json.inspect(logs, content=["callback message"])
}
