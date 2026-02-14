///|
test "executable" {
  let executable = @os.executable()
  json_inspect(executable == @os.args()[0], content=true)
}
