///|
test "int64" {
  inspect(
    @jsonx.int64(1234567890123456789).stringify(),
    content="1234567890123456789",
  )
}
