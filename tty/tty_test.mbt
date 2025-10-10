///|
test "windows_size" {
  @json.inspect((try? @tty.window_size()) is Err(_), content=true)
}
