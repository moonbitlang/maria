///|
pub async fn check_ignore(
  paths : Array[StringView],
  cwd? : StringView,
) -> Array[String] {
  let args : Array[StringView] = ["check-ignore"]
  for path in paths {
    args.push(path)
  }
  let process = @spawn.spawn("git", args, cwd?)
  process.check()
  let output = process.stdout.trim_space()
  if output.is_empty() {
    return []
  }
  output.split("\n").map(line => line.to_string()).collect()
}

///|
pub async fn is_ignored(path : StringView, cwd? : StringView) -> Bool {
  let ignored_paths = check_ignore([path], cwd?)
  return ignored_paths.contains(path.to_string())
}
