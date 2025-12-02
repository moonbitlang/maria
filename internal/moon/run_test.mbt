///|
async test "moon_run" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_files({
      "moon.pkg.json": Json::object({ "is_main": true }).stringify(indent=2),
      "moon.mod.json": Json::object({
        "name": "username/example",
        "version": "0.1.0",
      }).stringify(indent=2),
      "main.mbt": (
        #|///|
        #|fn main {
        #|  println(@env.args()[1:].to_json().stringify(indent=2))
        #|}
      ),
    })
    let moon = @moon.Module::load(mock.cwd.path())
    let (status, output) = moon.run(".", ["Hello, MoonBit!", "2"])
    @json.inspect(status, content=0)
    inspect(
      output,
      content=(
        #|[
        #|  "Hello, MoonBit!",
        #|  "2"
        #|]
        #|
      ),
    )
  })
}
