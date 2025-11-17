///|
pub async fn new(
  user? : String,
  name? : String,
  path : StringView,
  cwd? : StringView,
) -> Module {
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
  let process = @spawn.spawn("moon", arguments, cwd?)
  process.check()
  let path : StringView = if cwd is Some(cwd) {
    @path.join(cwd, path)
  } else if @path.is_absolute(path) {
    path
  } else {
    @path.join(@os.cwd(), path)
  }
  Module::load(path.to_string())
}
