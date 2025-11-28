///|
async test "lock_file" (t : @test.Test) {
  let cwd = @os.cwd()
  @mock.run(t, mock => {
    let file = mock.add_file("lockfile.txt")
    file.write_string("test content")
    let path = file.path()
    let file = @fs.open(path, mode=ReadWrite)
    @fsx.lock_file(file)
    let process = @spawn.spawn(
      @path.join(cwd, "target/native/release/build/cmd/test-lock/test-lock.exe"),
      [path],
    )
    @json.inspect(process.status != 0, content=true)
  })
}

///|
async test "get_lock_owner" (t : @test.Test) {
  let cwd = @os.cwd()
  @mock.run(t, mock => {
    let file = mock.add_file("lockfile.txt")
    file.write_string("test content")
    let path = file.path()
    {
      let file = @fs.open(path, mode=ReadWrite)
      defer file.close()
      @json.inspect(@fsx.get_lock_owner(file) == None, content=true)
    }
    let stdin = @process.write_to_process()
    let stdout = @process.read_from_process()
    let pid = @process.spawn_orphan(
      @path.join(cwd, "target/native/release/build/cmd/test-lock/test-lock.exe"),
      [path, "--stdin"],
      stdin=stdin.0,
      stdout=stdout.1,
      cwd~,
    )
    mock.group.add_defer(() => @spawn.kill(pid, @signal.sigterm))
    let _ = stdout.0.read_some()
    {
      let file = @fs.open(path, mode=ReadWrite)
      defer file.close()
      @json.inspect(@fsx.get_lock_owner(file) == Some(pid), content=true)
    }
    stdin.1.write(b"exit\n")
  })
}
