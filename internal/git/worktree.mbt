///|
pub async fn add_worktree(
  path : String,
  new_branch? : String,
  force_new_branch? : Bool = false,
  commit? : String,
  cwd? : StringView,
) -> Unit {
  let arguments : Array[StringView] = ["worktree", "add"]
  if new_branch is Some(branch) {
    if force_new_branch {
      arguments.push("-B")
    } else {
      arguments.push("-b")
    }
    arguments.push(branch)
  }
  arguments.push(path)
  if commit is Some(commit) {
    arguments.push(commit)
  }
  let status = @spawn.spawn("git", arguments, cwd?)
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
  new_branch? : String,
  force_new_branch? : Bool,
  commit? : String,
  cwd? : StringView,
  f : async () -> T,
) -> T {
  @async.with_task_group(group => {
    add_worktree(path, new_branch?, force_new_branch?, commit?, cwd?)
    group.add_defer(() => remove_worktree(path, force=true, cwd?))
    f()
  })
}
