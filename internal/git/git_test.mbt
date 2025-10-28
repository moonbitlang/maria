///|
async test "clone" (t : @test.T) {
  @mock.run(t, taco => {
    @git.clone("https://github.com/moonbitlang/maria.git", to=taco.cwd.path(), depth=1)
    let entries = taco.cwd.list().map((entry : @mock.Entry) => entry.name())
    @json.inspect(entries.contains("moon.mod.json"), content=true)
  })
}

///|
async test "commit" (t : @test.T) {
  if @os.getenv("CI") is None {
    @mock.run(t, taco => {
      @git.init_(taco.cwd.path())
      let _ = taco.add_file("file.txt", content="Hello, Moonbit!")
      @git.commit("Initial commit", ["file.txt"], cwd=taco.cwd.path())
    })
  }
}

///|
async test "generate_git_diff" {
  let original =
    #|line 1
    #|line 2
    #|line 3
  let modified =
    #|line 1
    #|line 2 modified
    #|line 3
    #|line 4 added
  let diff = @git.generate_git_diff(original~, modified~)
  inspect(
    diff
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
}
