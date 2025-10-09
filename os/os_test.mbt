///|
test "getenv" {
  ignore(@os.getenv("PATH"))
}

test "cwd" {
  ignore(@os.cwd())
}
