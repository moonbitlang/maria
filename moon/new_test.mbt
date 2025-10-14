///|
async test "new" {
  @async.with_task_group(group => {
    let cwd = @mock.directory("moon-new")
    group.add_defer(() => cwd.close())
    @moon.new(user="moonbitlang", name="maria_test", ".", cwd=cwd.path())
    @json.inspect(cwd.strip_cwd(@fs.list_directory(cwd.path())), content=[
      { "path": "./cmd", "name": "cmd", "kind": "Directory" },
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
