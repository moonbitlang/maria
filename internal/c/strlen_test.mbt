///|
test "strlen" {
  let s : @c.Pointer[Byte] = @c.malloc(6)
  s[0] = b'h'
  s[1] = b'e'
  s[2] = b'l'
  s[3] = b'l'
  s[4] = b'o'
  s[5] = 0
  json_inspect(@c.strlen(s), content="5")
}
