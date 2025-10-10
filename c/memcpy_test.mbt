///|
test "memcpy_from_bytes" {
  let bytes : Bytes = Bytes::makei(8, i => i.to_byte())
  let ptr : @c.Pointer[Byte] = @c.malloc(8)
  defer @c.free(ptr)
  @c.memcpy_from_bytes(ptr, bytes, 8)
  @json.inspect(ptr[0], content=0)
  @json.inspect(ptr[1], content=1)
  @json.inspect(ptr[2], content=2)
  @json.inspect(ptr[3], content=3)
  @json.inspect(ptr[4], content=4)
  @json.inspect(ptr[5], content=5)
  @json.inspect(ptr[6], content=6)
  @json.inspect(ptr[7], content=7)
}

///|
test "memcpy_to_bytes" {
  let bytes = Bytes::make(8, 0)
  let ptr : @c.Pointer[Byte] = @c.malloc(8)
  defer @c.free(ptr)
  ptr[0] = 0
  ptr[1] = 1
  ptr[2] = 2
  ptr[3] = 3
  ptr[4] = 4
  ptr[5] = 5
  ptr[6] = 6
  ptr[7] = 7
  @c.memcpy_to_bytes(bytes, ptr, 8)
}
