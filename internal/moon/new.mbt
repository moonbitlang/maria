///|
pub async fn new(
  user? : String,
  name? : String,
  path : StringView,
  cwd? : StringView,
) -> Unit {
  let arguments : Array[StringView] = ["new"]
  if user is Some(user) {
    arguments.push("--user")
    arguments.push(user)
  }
  if name is Some(name) {
    arguments.push("--name")
    arguments.push(name)
  }
  arguments.push(path)
  let stdout = StringBuilder::new()
  let status = @spawn.spawn("moon", arguments, cwd?, stdout~)
  if status != 0 {
    fail("moon new failed with status \{status}:\n\{stdout.to_string()}")
  }
}
