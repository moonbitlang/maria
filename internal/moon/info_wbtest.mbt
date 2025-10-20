///|
async test "info" (t : @test.T) {
  @mock.run(t, taco => {
    taco.add_files([
      (
        "moon.mod.json",
        (
          #|{ "name": "example", "version": "0.1.0" }
        ),
      ),
      (
        "moon.pkg.json",
        (
          #|{ }
        ),
      ),
      ("example.mbt", "///|\nlet x : Int = 42"),
    ])
    info(cwd=taco.cwd.path())
  })
}
