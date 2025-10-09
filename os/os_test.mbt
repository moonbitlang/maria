///|
test "getenv" {
  ignore(@os.getenv("PATH"))
}

///|
test "unsetenv" {
  @os.unsetenv("HOME")
  @json.inspect(@os.getenv("HOME"), content=null)
}

///|
test "cwd" {
  ignore(@os.cwd())
}

///|
test "home" {
  if @os.getenv("HOME") is Some(home) {
    @os.unsetenv("HOME")
    @json.inspect(@os.home(), content=home.to_json())
  } else {
    ignore(@os.home())
  }
}

///|
test "tmpdir" {
  ignore(@os.tmpdir())
}
