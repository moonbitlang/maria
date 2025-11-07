///|
async fn run(
  cwd? : StringView,
  package_or_file : String,
  arguments : Array[String],
) -> (Int, String) {
  let cwd : StringView = match cwd {
    None => @os.cwd()
    Some(cwd) =>
      if @path.is_absolute(cwd) {
        cwd
      } else {
        @path.join(@os.cwd(), cwd)
      }
  }
  let args : Array[StringView] = ["run", package_or_file]
  if !arguments.is_empty() {
    args.push("--")
    for argument in arguments {
      args.push(argument)
    }
  }
  let result = @spawn.spawn("moon", args, cwd~)
  (result.status, result.stdout)
}
