///|
async test "executable" {
  let executable = @os.executable()
  // Suppress unused package warnings.
  ignore(@moon.home())
  ignore(@path.join("a", "b"))
  @json.inspect(executable == @os.args()[0], content=true)
}
