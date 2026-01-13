///|
test "display_position_wide_chars" {
  let bytes = @encoding/utf8.encode("你好")
  let pos = display_position(bytes, col=80, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 4)
  assert_eq(pos.rows, 0)
}

///|
test "display_position_combining_marks" {
  let bytes = @encoding/utf8.encode("a\u{0301}b")
  let pos = display_position(bytes, col=80, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 2)
  assert_eq(pos.rows, 0)
}

///|
test "display_position_tab_alignment" {
  let bytes = @encoding/utf8.encode("a\tb")
  let pos = display_position(bytes, col=80, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 5)
  assert_eq(pos.rows, 0)
}

///|
test "display_position_multiline_prompt" {
  let bytes = @encoding/utf8.encode("a\nb")
  let pos = display_position(bytes, col=80, is_multiline=true, tab_size=4)
  assert_eq(pos.cols, 3)
  assert_eq(pos.rows, 1)
}

///|
test "display_position_wraps_wide_chars" {
  let bytes = @encoding/utf8.encode("你好")
  let pos = display_position(bytes, col=4, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 0)
  assert_eq(pos.rows, 1)
}
