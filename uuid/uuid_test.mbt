///|
test "parse" {
  let hex = "72212911-64d1-c441-e87d-de89b955ea34"
  @json.inspect(@uuid.parse(hex) == @uuid.parse(hex), content=true)
  @json.inspect(
    @uuid.parse(hex).to_string(),
    content="72212911-64d1-c441-e87d-de89b955ea34",
  )
  let hex = "13cb501c-1234-5678-9034-abcdef937e20"
  inspect(@uuid.parse(hex), content=hex)
  inspect(
    @uuid.parse("12345678-1234-1234-1234-ABCDEF098765"),
    content="12345678-1234-1234-1234-abcdef098765",
  )
  @json.inspect(try? @uuid.parse("13cb"), content={ "Err": "UnexpectedEnd" })
  @json.inspect(try? @uuid.parse("13cb501c-99a8-c889-3234"), content={
    "Err": ["MissingDash", ""],
  })
  @json.inspect(try? @uuid.parse("g"), content={ "Err": ["InvalidOctet", "g"] })
  @json.inspect(try? @uuid.parse("13cb501c-1234-5678-9034-abcdef937e20g"), content={
    "Err": ["ExtraContent", "g"],
  })
}

///|
test "to_bytes" {
  let hex = "72212911-64d1-c441-e87d-de89b955ea34"
  let uuid = @uuid.parse(hex)
  @json.inspect(uuid.to_bytes().to_array(), content=[
    0x72, 0x21, 0x29, 0x11, 0x64, 0xd1, 0xc4, 0x41, 0xe8, 0x7d, 0xde, 0x89, 0xb9,
    0x55, 0xea, 0x34,
  ])
}

///|
test "v4" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @json.inspect(@uuid.v4(rand~) == @uuid.v4(rand~), content=false)
  @json.inspect(@uuid.v4(rand~).variant(), content=["RFC9562", "V4"])
  @json.inspect(@uuid.v4(rand~).version(), content=["V4"])
}

///|
test "Uuid::variant" {
  @json.inspect(
    @uuid.parse("81a277a6-771b-1a55-6246-fa3763226aa0").variant(),
    content="ReservedNCS",
  )
  @json.inspect(@uuid.parse("42e0e55d-cee5-044c-b3a6-18a7dc5ae8b4").variant(), content=[
    "RFC9562", "V0",
  ])
  @json.inspect(
    @uuid.parse("1db64c57-6b48-fd91-dab2-d3accd060480").variant(),
    content="ReservedMicrosoft",
  )
  @json.inspect(
    @uuid.parse("96b2d68d-f97d-9358-f2b1-79cbc6d43c83").variant(),
    content="ReservedFuture",
  )
}

///|
test "Uuid::version" {
  let u = @uuid.parse("907976bf-6784-5a4f-5d7d-33c04dd8fa1a")
  @json.inspect(u.version(), content=null)
}

///|
test "nil" {
  @json.inspect(@uuid.nil, content="00000000-0000-0000-0000-000000000000")
  @json.inspect(@uuid.nil.variant(), content="ReservedNCS")
  @json.inspect(@uuid.nil.version(), content=null)
}

///|
test "max" {
  @json.inspect(@uuid.max, content="ffffffff-ffff-ffff-ffff-ffffffffffff")
  @json.inspect(@uuid.max.variant(), content="ReservedFuture")
  @json.inspect(@uuid.max.version(), content=null)
}

///|
test "compare" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  @json.inspect(@uuid.nil < @uuid.max, content=true)
  @json.inspect(@uuid.nil < @uuid.v4(rand~), content=true)
  @json.inspect(@uuid.v4(rand~) < @uuid.max, content=true)
}

///|
test "hash" {
  let rand = @rand.chacha8(seed="ABCDEFGHIJKLMNOPQRSTUVWXYZ123456")
  let v4 = @uuid.v4(rand~)
  @json.inspect(v4.hash() == v4.hash(), content=true)
  @json.inspect(@uuid.v4(rand~).hash() != @uuid.v4(rand~).hash(), content=true)
}
