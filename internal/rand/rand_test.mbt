///|
test "bytes" {
  let bytes = @rand.bytes(16)
  json_inspect(bytes.length(), content=16)
}
