///|
test "windows_size" {
  @json.inspect(try? @tty.window_size(), content={
    "Err": "Operation not supported by device",
  })
}
