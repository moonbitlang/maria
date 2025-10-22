///|
pub async fn delete_branch(
  force? : Bool = false,
  branch : String,
  cwd? : StringView,
) -> Unit {
  let arguments : Array[StringView] = ["branch"]
  if force {
    arguments.push("-D")
  } else {
    arguments.push("-d")
  }
  arguments.push(branch)
  let status = @spawn.spawn("git", arguments, cwd?)
  guard status is 0 else {
    fail("git branch delete failed with status code \{status}")
  }
}

///|
pub async fn create_branch(
  branch : String,
  start_point? : String,
  cwd? : StringView,
) -> Unit {
  let arguments : Array[StringView] = ["branch", branch]
  if start_point is Some(start_point) {
    arguments.push(start_point)
  }
  let status = @spawn.spawn("git", arguments, cwd?)
  guard status is 0 else {
    fail("git branch create failed with status code \{status}")
  }
}
