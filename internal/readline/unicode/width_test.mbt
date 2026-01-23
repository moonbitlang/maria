///|
test "char_width_left" {
  let string : Bytes = "aあ𠮷👋🌍🙂‍↕️"
  json_inspect(@unicode.char_width_left(string, 0), content=0)
  json_inspect(@unicode.char_width_left(string, 4), content=2)
  json_inspect(@unicode.char_width_left(string, 8), content=2)
  json_inspect(@unicode.char_width_left(string, 12), content=2)
  json_inspect(@unicode.char_width_left(string, 16), content=2)
  json_inspect(@unicode.char_width_left(string, string.length()), content=0)
}

///|
test "char_width_right" {
  let string : Bytes = "aあ𠮷👋🌍🙂‍↕️"
  json_inspect(@unicode.char_width_right(string, 0), content=1)
  json_inspect(@unicode.char_width_right(string, 1), content=2)
  json_inspect(@unicode.char_width_right(string, 4), content=2)
  json_inspect(@unicode.char_width_right(string, 8), content=2)
  json_inspect(@unicode.char_width_right(string, 12), content=2)
  json_inspect(@unicode.char_width_right(string, 16), content=2)
}

///|
test "char_size_left_byte_lengths" {
  let ascii = @encoding/utf8.encode("a")
  let cents = @encoding/utf8.encode("\u{00A2}")
  let hira = @encoding/utf8.encode("\u{3042}")
  let yoshi = @encoding/utf8.encode("\u{20BB7}")
  let string : Bytes = [..ascii, ..cents, ..hira, ..yoshi]
  let idx_a = ascii.length()
  let idx_cents = idx_a + cents.length()
  let idx_hira = idx_cents + hira.length()
  let idx_yoshi = idx_hira + yoshi.length()
  assert_eq(@unicode.char_size_left(string, 0), 0)
  assert_eq(@unicode.char_size_left(string, idx_a), ascii.length())
  assert_eq(@unicode.char_size_left(string, idx_cents), cents.length())
  assert_eq(@unicode.char_size_left(string, idx_hira), hira.length())
  assert_eq(@unicode.char_size_left(string, idx_yoshi), yoshi.length())
}

///|
test "char_size_left_combining_marks" {
  let combining = @encoding/utf8.encode("a\u{0301}")
  assert_eq(
    @unicode.char_size_left(combining, combining.length()),
    combining.length(),
  )
  let multiple = @encoding/utf8.encode("a\u{0301}\u{0308}")
  assert_eq(
    @unicode.char_size_left(multiple, multiple.length()),
    multiple.length(),
  )
  let mixed = @encoding/utf8.encode("a\u{0301}b")
  let idx_combining = combining.length()
  assert_eq(@unicode.char_size_left(mixed, idx_combining), combining.length())
  assert_eq(@unicode.char_size_left(mixed, mixed.length()), 1)
}

///|
test "char_size_left_variation_selector" {
  let with_vs16 = @encoding/utf8.encode("\u{261D}\u{FE0F}")
  assert_eq(
    @unicode.char_size_left(with_vs16, with_vs16.length()),
    with_vs16.length(),
  )
  let mixed = @encoding/utf8.encode("\u{261D}\u{FE0F}a")
  let idx_vs16 = with_vs16.length()
  assert_eq(@unicode.char_size_left(mixed, idx_vs16), with_vs16.length())
  assert_eq(@unicode.char_size_left(mixed, mixed.length()), 1)
}

///|
test "char_size_left_zwj_sequence" {
  let base = @encoding/utf8.encode("\u{1F469}")
  let zwj = @encoding/utf8.encode("\u{200D}")
  let tool = @encoding/utf8.encode("\u{1F52C}")
  let sequence : Bytes = [..base, ..zwj, ..tool]
  assert_eq(@unicode.char_size_left(sequence, sequence.length()), tool.length())
}

///|
test "char_width_left_right_zero_width" {
  let combining = @encoding/utf8.encode("a\u{0301}b")
  assert_eq(@unicode.char_width_left(combining, 1), 1)
  assert_eq(@unicode.char_width_left(combining, 3), 0)
  assert_eq(@unicode.char_width_right(combining, 1), 0)
  assert_eq(@unicode.char_width_right(combining, 3), 1)
}

///|
test "char_width_fallback_on_mid_sequence" {
  let hira = @encoding/utf8.encode("\u{3042}")
  assert_eq(@unicode.char_width_left(hira, 1), 1)
  assert_eq(@unicode.char_width_left(hira, 2), 1)
  assert_eq(@unicode.char_width_right(hira, 1), 1)
  assert_eq(@unicode.char_width_right(hira, 2), 1)
  assert_eq(@unicode.char_size_left(hira, 1), 1)
  assert_eq(@unicode.char_size_left(hira, 2), 1)
}

///|
test "char_size_right_widths" {
  let string = @encoding/utf8.encode("a\u{0301}\u{3042}")
  assert_eq(@unicode.char_size_right(string, 0), 3)
  assert_eq(@unicode.char_size_right(string, 1), 2)
  assert_eq(@unicode.char_size_right(string, 3), 3)
  assert_eq(@unicode.char_size_right(string, string.length()), 0)
}
