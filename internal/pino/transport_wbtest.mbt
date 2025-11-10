///|
async test "Transport::Channel" {
  let channel = @aqueue.new()
  let transport = Transport::chan(channel)
  transport.write(Json::string("test message"))
  @json.inspect(channel.try_get(), content=["test message"])
}
