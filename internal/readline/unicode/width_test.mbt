///|
test "char_width_left" {
  let string : Bytes = "aあ𠮷👋🌍🙂‍↕️"
  @json.inspect(@unicode.char_width_left(string, 0), content=0)
  @json.inspect(@unicode.char_width_left(string, 4), content=2)
  @json.inspect(@unicode.char_width_left(string, 8), content=2)
  @json.inspect(@unicode.char_width_left(string, 12), content=2)
  @json.inspect(@unicode.char_width_left(string, 16), content=2)
  @json.inspect(@unicode.char_width_left(string, string.length()), content=0)
}

///|
test "char_width_right" {
  let string : Bytes = "aあ𠮷👋🌍🙂‍↕️"
  @json.inspect(@unicode.char_width_right(string, 0), content=1)
  @json.inspect(@unicode.char_width_right(string, 1), content=2)
  @json.inspect(@unicode.char_width_right(string, 4), content=2)
  @json.inspect(@unicode.char_width_right(string, 8), content=2)
  @json.inspect(@unicode.char_width_right(string, 12), content=2)
  @json.inspect(@unicode.char_width_right(string, 16), content=2)
}
