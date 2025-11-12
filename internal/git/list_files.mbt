///|
pub async fn list_files(cwd? : StringView) -> Array[String] {
  let process = @spawn.spawn("git", ["ls-files"], cwd?)
  process.check()
  let output = process.stdout.trim_space()
  if output.is_empty() {
    return []
  }
  output.split("\n").map(line => line.to_string()).collect()
}
