///|
pub async fn add_worktree(path : String, cwd? : StringView) -> Unit {
  let status = @spawn.spawn("git", ["worktree", "add", path], cwd?)
  guard status is 0 else {
    fail("git worktree add failed with status code \{status}")
  }
}

///|
pub async fn remove_worktree(
  path : String,
  force? : Bool = false,
  cwd? : StringView,
) -> Unit {
  let arguments : Array[StringView] = ["worktree", "remove", path]
  if force {
    arguments.push("--force")
  }
  let status = @spawn.spawn("git", arguments, cwd?)
  guard status is 0 else {
    fail("git worktree remove failed with status code \{status}")
  }
}

///|
pub async fn[T] with_worktree(
  path : String,
  cwd? : StringView,
  f : async () -> T,
) -> T {
  @async.with_task_group(group => {
    add_worktree(path, cwd?)
    group.add_defer(() => remove_worktree(path, force=true, cwd?))
    f()
  })
}
