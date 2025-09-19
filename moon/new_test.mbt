///|
async test "new" {
  @async.with_task_group(group => {
    let cwd = @mock.directory("moon-new")
    group.add_defer(() => cwd.close())
    @moon.new(user="moonbitlang", name="maria_test", ".", cwd=cwd.path())
  })
}
