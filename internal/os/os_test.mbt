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

///|
test "gethostname" {
  ignore(@os.gethostname())
}

///|
async test "exit" {
  let args = @os.args()
  match args {
    [exec, args] => {
      if exec.has_suffix(".c") {
        return
      }
      @json.inspect(@spawn.spawn(exec, [args, "42"]).status, content=42)
    }
    [_, _, exit_code] => {
      @os.exit(@strconv.parse_int(exit_code))
      fail("unreachable")
    }
    _ => fail("Invalid arguments")
  }
}
