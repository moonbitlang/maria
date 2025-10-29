///|
test "strlen" {
  let s : @c.Pointer[Byte] = @c.malloc(6)
  s[0] = 'h'
  s[1] = 'e'
  s[2] = 'l'
  s[3] = 'l'
  s[4] = 'o'
  s[5] = 0
  @json.inspect(@c.strlen(s), content="5")
}
