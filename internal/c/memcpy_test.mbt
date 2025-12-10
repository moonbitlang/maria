///|
test "memcpy" {
  let src : @c.Pointer[Byte] = @c.malloc(16)
  for i in 0..<16 {
    src[i] = i.to_byte()
  }
  defer @c.free(src)
  let dst : @c.Pointer[Byte] = @c.malloc(16)
  for i in 0..<16 {
    dst[i] = 0
  }
  defer @c.free(dst)
  @c.memcpy(dst, src, 16)
}
