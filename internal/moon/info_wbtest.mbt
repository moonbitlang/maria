///|
async test "info" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_files([
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
    info(cwd=mock.cwd.path())
  })
}
