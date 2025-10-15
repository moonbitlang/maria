///|
async test "new" (t : @test.T) {
  @mock.run(t, taco => {
    @moon.new(user="moonbitlang", name="maria_test", ".", cwd=taco.cwd.path())
    let entries = @fs.list_directory(taco.cwd.path())
    @json.inspect(taco.json(entries), content=[
      { "path": "./cmd", "name": "cmd", "kind": "Directory" },
      { "path": "./.git", "name": ".git", "kind": "Directory" },
      { "path": "./.github", "name": ".github", "kind": "Directory" },
      { "path": "./LICENSE", "name": "LICENSE", "kind": "Regular" },
      { "path": "./.githooks", "name": ".githooks", "kind": "Directory" },
      { "path": "./AGENTS.md", "name": "AGENTS.md", "kind": "Regular" },
      { "path": "./README.md", "name": "README.md", "kind": "Regular" },
      { "path": "./.gitignore", "name": ".gitignore", "kind": "Regular" },
      { "path": "./README.mbt.md", "name": "README.mbt.md", "kind": "Regular" },
      { "path": "./moon.mod.json", "name": "moon.mod.json", "kind": "Regular" },
      { "path": "./moon.pkg.json", "name": "moon.pkg.json", "kind": "Regular" },
      {
        "path": "./maria_test.mbt",
        "name": "maria_test.mbt",
        "kind": "Regular",
      },
      {
        "path": "./maria_test_test.mbt",
        "name": "maria_test_test.mbt",
        "kind": "Regular",
      },
    ])
  })
}
