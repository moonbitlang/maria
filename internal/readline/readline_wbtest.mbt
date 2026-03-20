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

///|
test "display_position_zero_col_returns_zero" {
  let bytes = @encoding/utf8.encode("hello")
  let pos = display_position(bytes, col=0, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 0)
  assert_eq(pos.rows, 0)
}

///|
test "display_position_empty_string" {
  let bytes : Bytes = ""
  let pos = display_position(bytes, col=80, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 0)
  assert_eq(pos.rows, 0)
}

///|
test "display_position_ascii_wrapping" {
  let bytes = @encoding/utf8.encode("abcde")
  let pos = display_position(bytes, col=3, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 2)
  assert_eq(pos.rows, 1)
}

///|
test "display_position_newline_not_multiline" {
  let bytes = @encoding/utf8.encode("ab\ncd")
  let pos = display_position(bytes, col=80, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 2)
  assert_eq(pos.rows, 1)
}

///|
test "display_position_multiple_newlines_multiline" {
  let bytes = @encoding/utf8.encode("a\nb\nc")
  let pos = display_position(bytes, col=80, is_multiline=true, tab_size=4)
  // After first \n: row 1, offset starts at MultilinePrompt.length()=2, then 'b' -> offset=3
  // After second \n: row 2, offset starts at 2, then 'c' -> offset=3
  assert_eq(pos.cols, 3)
  assert_eq(pos.rows, 2)
}

///|
test "display_position_tab_at_boundary" {
  let bytes = @encoding/utf8.encode("\t")
  let pos = display_position(bytes, col=80, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 4)
  assert_eq(pos.rows, 0)
}

///|
test "display_position_4byte_utf8_emoji" {
  let bytes = @encoding/utf8.encode("\u{1F600}")
  let pos = display_position(bytes, col=80, is_multiline=false, tab_size=4)
  assert_eq(pos.cols, 2)
  assert_eq(pos.rows, 0)
}

///|
test "history_manager_add_and_navigate" {
  let hm = HistoryManager::new(10)
  let _ = hm.add_history("first", is_multiline=false, last_command_errored=false)
  let _ = hm.add_history("second", is_multiline=false, last_command_errored=false)
  assert_true(hm.can_navigate_to_prev())
  assert_false(hm.can_navigate_to_next())
}

///|
test "history_manager_navigate_previous" {
  let hm = HistoryManager::new(10)
  let _ = hm.add_history("first", is_multiline=false, last_command_errored=false)
  let _ = hm.add_history("second", is_multiline=false, last_command_errored=false)
  let result = hm.navigate_to_previous("")
  assert_true(result is Some(_))
}

///|
test "history_manager_navigate_next_at_start" {
  let hm = HistoryManager::new(10)
  let _ = hm.add_history("first", is_multiline=false, last_command_errored=false)
  let result = hm.navigate_to_next("")
  assert_true(result is None)
}

///|
test "history_manager_empty_line_not_added" {
  let hm = HistoryManager::new(10)
  let result = hm.add_history("", is_multiline=false, last_command_errored=false)
  assert_true(result == "")
  assert_false(hm.can_navigate_to_prev())
}

///|
test "history_manager_whitespace_only_not_added" {
  let hm = HistoryManager::new(10)
  let _ = hm.add_history("   ", is_multiline=false, last_command_errored=false)
  assert_false(hm.can_navigate_to_prev())
}

///|
test "history_manager_size_limit" {
  let hm = HistoryManager::new(2)
  let _ = hm.add_history("first", is_multiline=false, last_command_errored=false)
  let _ = hm.add_history("second", is_multiline=false, last_command_errored=false)
  let _ = hm.add_history("third", is_multiline=false, last_command_errored=false)
  assert_eq(hm.history.length(), 2)
}

///|
test "history_manager_duplicate_not_added" {
  let hm = HistoryManager::new(10)
  let _ = hm.add_history("same", is_multiline=false, last_command_errored=false)
  let _ = hm.add_history("same", is_multiline=false, last_command_errored=false)
  assert_eq(hm.history.length(), 1)
}

///|
test "history_manager_zero_size" {
  let hm = HistoryManager::new(0)
  let result = hm.add_history("test", is_multiline=false, last_command_errored=false)
  assert_true(result == "test")
  assert_false(hm.can_navigate_to_prev())
}

///|
test "word_size_left_at_start" {
  let result = word_size_left("hello world", 0)
  assert_eq(result, 0)
}

///|
test "word_size_left_after_word" {
  let s : BytesView = "hello world"
  let result = word_size_left(s, 5)
  assert_true(result >= 0)
}

///|
test "word_size_left_at_end" {
  let s : BytesView = "hello"
  let result = word_size_left(s, 5)
  assert_true(result >= 0)
}

///|
test "word_right_left_at_end" {
  let s : BytesView = "hello"
  let result = word_right_left(s, 5)
  assert_eq(result, 0)
}

///|
test "word_right_left_at_start" {
  let s : BytesView = "hello world"
  let result = word_right_left(s, 0)
  assert_true(result >= 0)
}

///|
test "common_prefix_empty_array" {
  let result = common_prefix([])
  assert_eq(result, "")
}

///|
test "common_prefix_single_element" {
  let result = common_prefix(["hello"])
  assert_eq(result, "hello")
}

///|
test "common_prefix_shared_prefix" {
  let result = common_prefix(["abc", "abd", "abe"])
  assert_eq(result, "ab")
}

///|
test "common_prefix_no_common" {
  let result = common_prefix(["abc", "xyz"])
  assert_eq(result, "")
}

///|
test "common_prefix_identical" {
  let result = common_prefix(["same", "same", "same"])
  assert_eq(result, "same")
}

///|
test "bytesview_split_basic" {
  let input : BytesView = "a\nb\nc"
  let parts = input.split('\n')
  assert_eq(parts.length(), 3)
}

///|
test "bytesview_split_no_separator" {
  let input : BytesView = "hello"
  let parts = input.split('\n')
  assert_eq(parts.length(), 1)
}

///|
test "bytesview_split_empty" {
  let input : BytesView = ""
  let parts = input.split('\n')
  assert_eq(parts.length(), 1)
}

///|
test "bytesview_split_trailing_separator" {
  let input : BytesView = "a\nb\n"
  let parts = input.split('\n')
  assert_eq(parts.length(), 3)
}

///|
test "bytesview_trim_start" {
  let input : BytesView = "  hello"
  let result = input.trim_start()
  assert_true(result == "hello")
}

///|
test "bytesview_trim_end" {
  let input : BytesView = "hello  "
  let result = input.trim_end()
  assert_true(result == "hello")
}

///|
test "bytesview_trim_both" {
  let input : BytesView = "  hello  "
  let result = input.trim()
  assert_true(result == "hello")
}

///|
test "bytesview_trim_empty" {
  let input : BytesView = ""
  let result = input.trim()
  assert_true(result == "")
}

///|
test "bytesview_trim_all_spaces" {
  let input : BytesView = "   "
  let result = input.trim()
  assert_true(result == "")
}

///|
test "reverse_string_three_parts" {
  let input : BytesView = "line1\nline2\nline3"
  let result = reverse_string(input, from='\n', to='\r')
  assert_true(result == "line3\rline2\rline1")
}

///|
test "reverse_string_no_separator" {
  let input : BytesView = "hello"
  let result = reverse_string(input, from='\n', to='\r')
  assert_true(result == "hello")
}

///|
test "reverse_string_single_separator" {
  let input : BytesView = "a\nb"
  let result = reverse_string(input, from='\n', to='\r')
  assert_true(result == "b\ra")
}

///|
test "kill_ring_max_length_constant" {
  assert_eq(MaxLengthOfKillRing, 32)
}
