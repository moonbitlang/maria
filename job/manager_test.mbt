///|
async test "Manager::spawn" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @job.Manager::new(cwd=mock.cwd.path())
    mock.group.spawn_bg(() => manager.start(), no_wait=true)
    let job = manager.spawn(name="sleep", command="sleep 2")
    json_inspect(job.status(), content=null)
    json_inspect(job.id, content=0)
    json_inspect(job.command, content="sleep 2")
    json_inspect(mock.json(job.cwd), content="(mock:cwd)")
    json_inspect(
      mock.json(job.stdout),
      content="(mock:cwd)/.moonagent/jobs/0/stdout",
    )
    json_inspect(
      mock.json(job.stderr),
      content="(mock:cwd)/.moonagent/jobs/0/stderr",
    )
  })
}

///|
async test "Manager::wait" (t : @test.Test) {
  @mock.run(t, mock => {
    let manager = @job.Manager::new(cwd=mock.cwd.path())
    mock.group.spawn_bg(() => manager.start(), no_wait=true)
    let job = manager.spawn(name="sleep", command="sleep 2")
    json_inspect(job.status(), content=null)
    let _ = job.wait()
    json_inspect(job.status(), content=[0])
  })
}
