///|
test "Jason::from_json" {
  let jason : Jason = Jason::from_json(1.2)
  @jason.inspect(jason, content=1.2)
}
