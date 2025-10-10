///|
test "bytes" {
  let bytes = @rand.bytes(16)
  @json.inspect(bytes.length(), content=16)
}
