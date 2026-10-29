///|
test "windows_size" {
  json_inspect(
    (Ok(@tty.window_size()) catch { error => Err(error) }) is Err(_),
    content=true,
  )
}
