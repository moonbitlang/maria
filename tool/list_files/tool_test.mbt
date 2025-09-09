///|
async fn write_file(path : Bytes, content : @bytes.View) -> Unit raise {
  let file = @fs.open(path, mode=WriteOnly, create=0o644)
  defer file.close()
  file.write(content)
}

///|
async fn remove_directory(path : Bytes) -> Unit raise {
  let dir = @fs.opendir(path)
  defer dir.close()
  for entry in dir.read_all() {
    let entry = @path.join(path, entry)
    match @fs.kind(entry) {
      Directory => remove_directory(entry)
      _ => @fs.remove(entry)
    }
  }
  @fs.rmdir(path)
}

///|
test "list_files" {
  let uv = @uv.Loop::new()
  @async.with_event_loop(g => {
    // Create a mock directory.
    if !@fs.exists(".tmp") {
      @fs.mkdir(".tmp", permission=0o755)
    }
    let tmpdir = uv.fs_mkdtemp_sync(
      @path.join(".tmp", "maria-tool-list-files-test-XXXXXX"),
    )
    g.add_defer(() => remove_directory(tmpdir))
    write_file(@path.join(tmpdir, "moon.pkg.json"), "{}")
    write_file(@path.join(tmpdir, "tool.mbt"), "// tool")
    write_file(@path.join(tmpdir, "tool_test.mbt"), "// test")
    let cwd = @utf8.decode(tmpdir)
    inspect(
      (list_files.f)({ "path": "." }, @tool.context(cwd~)).output,
      content=(
        #|tool.mbt
        #|moon.pkg.json
        #|tool_test.mbt
      ),
    )
  })
}
