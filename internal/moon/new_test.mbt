///|
async test "new" (t : @test.Test) {
  @mock.run(t, mock => {
    @moon.new(user="moonbitlang", name="maria_test", ".", cwd=mock.cwd.path())
    let entries = @fsx.list_directory(mock.cwd.path())
    json_inspect(mock.json(entries), content=[
      { "path": "(mock:cwd)/cmd", "name": "cmd", "kind": "Directory" },
      { "path": "(mock:cwd)/.git", "name": ".git", "kind": "Directory" },
      { "path": "(mock:cwd)/.github", "name": ".github", "kind": "Directory" },
      { "path": "(mock:cwd)/LICENSE", "name": "LICENSE", "kind": "Regular" },
      {
        "path": "(mock:cwd)/.githooks",
        "name": ".githooks",
        "kind": "Directory",
      },
      { "path": "(mock:cwd)/AGENTS.md", "name": "AGENTS.md", "kind": "Regular" },
      { "path": "(mock:cwd)/README.md", "name": "README.md", "kind": "SymLink" },
      {
        "path": "(mock:cwd)/.gitignore",
        "name": ".gitignore",
        "kind": "Regular",
      },
      {
        "path": "(mock:cwd)/README.mbt.md",
        "name": "README.mbt.md",
        "kind": "Regular",
      },
      {
        "path": "(mock:cwd)/moon.mod.json",
        "name": "moon.mod.json",
        "kind": "Regular",
      },
      {
        "path": "(mock:cwd)/moon.pkg.json",
        "name": "moon.pkg.json",
        "kind": "Regular",
      },
      {
        "path": "(mock:cwd)/maria_test.mbt",
        "name": "maria_test.mbt",
        "kind": "Regular",
      },
      {
        "path": "(mock:cwd)/maria_test_test.mbt",
        "name": "maria_test_test.mbt",
        "kind": "Regular",
      },
    ])
  })
}
