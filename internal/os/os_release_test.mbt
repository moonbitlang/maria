///|
test "executable" {
  let executable = @os.executable()
  // Suppress unused package warnings.
  ignore(@moon.home())
  ignore(@pathx.join("a", "b"))
  json_inspect(executable == @os.args()[0], content=true)
}
