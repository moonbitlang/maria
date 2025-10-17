///|
test "getpid" {
  ignore(@spawn.getpid())
  ignore(@spawn.getppid())
}

///|
async test "Manager::spawn" (t : @test.T) {
  @mock.run(t, mock => {
    let manager = @spawn.Manager::new(cwd=mock.cwd.path())
    mock.group.spawn_bg(() => manager.start(), no_wait=true)
    let process = manager.spawn("sleep", ["2"])
    @json.inspect(process.pid, content=0)
  })
}

///|
async test "Manager::wait" (t : @test.T) {
  @mock.run(t, mock => {
    let manager = @spawn.Manager::new(cwd=mock.cwd.path())
    mock.group.spawn_bg(() => manager.start(), no_wait=true)
    let process = manager.spawn("sleep", ["2"])
    let status = process.wait()
    @json.inspect(status, content=0)
  })
}
