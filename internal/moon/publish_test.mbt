///|
async test "publish" (t : @test.Test) {
  @mock.run(t, mock => {
    mock
    .add_file("moon.mod.json")
    .write_json({
      "name": "username/example",
      "version": "0.1.0",
      "description": "A test module for publish",
      "authors": ["tester"],
      "license": "MIT",
    })
    mock.add_file("moon.pkg.json").write_json({})
    mock
    .add_file("index.mbt")
    .write_string(
      (
        #|fn main() {
        #|  println("Hello, Moonbit!")
        #|}
      ),
    )
    let moon = @moon.Module::load(mock.cwd.path())
    @json.inspect(
      (try? moon.publish(dry_run=true)).to_json()
      is { "Err": ["Failed", { "status": status, .. }], .. } &&
      status != 0,
      content=true,
    )
  })
}
