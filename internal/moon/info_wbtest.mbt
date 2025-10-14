///|
async test "info" (t : @test.T) {
  @taco.run(t, taco => {
    let _ = taco.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = taco.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let _ = taco.add_file("example.mbt", content="///|\nlet x : Int = 42")
    info(cwd=taco.cwd.path())
  })
}
