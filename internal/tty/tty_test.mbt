///|
test "windows_size" {
  json_inspect((try? @tty.window_size()) is Err(_), content=true)
}
