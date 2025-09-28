///|
async test "clone" {
  // FIXME: Enable this test after we have a way to mock git repositories.
  if false {
    @async.with_task_group(g => {
      let repo = @mock.directory("git-clone")
      g.add_defer(() => repo.close())
      @git.clone("https://github.com/moonbitlang/maria.git", to=repo.path())
      let entries = repo.list()
      @json.inspect(entries.contains("moon.mod.json"), content=true)
    })
  }
}

///|
async test "commit" {
  @async.with_timeout(10_000, () => @async.with_task_group(g => {
    let repo = @mock.directory("git-commit")
    g.add_defer(() => repo.close())
    @git.init_(repo.path())
    let _ = repo.add_file("file.txt", "Hello, Moonbit!")
    @git.commit("Initial commit", ["file.txt"], cwd=repo.path())
  }))
}

///|
async test "generate_git_diff" {
  @async.with_task_group(_ => {
    let original =
      #|line 1
      #|line 2
      #|line 3
    let modified =
      #|line 1
      #|line 2 modified
      #|line 3
      #|line 4 added
    inspect(
      @git.generate_git_diff(original~, modified~)
      .split("\n")
      .drop_while(line => !line.contains("@@"))
      .collect()
      .join("\n"),
      content=(
        #|@@ -1,3 +1,4 @@
        #| line 1
        #|-line 2
        #|-line 3
        #|\ No newline at end of file
        #|+line 2 modified
        #|+line 3
        #|+line 4 added
        #|\ No newline at end of file
        #|
      ),
    )
  })
}
