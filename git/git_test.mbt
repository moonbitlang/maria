///|
test "generate_git_diff" {
  @async.with_event_loop(_ => {
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
