///|
async fn info(cwd? : StringView) -> Unit {
  let arguments : Array[StringView] = ["info"]
  let output = StringBuilder::new()
  let status = @spawn.spawn("moon", arguments, output~, cwd?)
  guard status is 0 else {
    fail("moon info failed with status \{status}:\n\{output}")
  }
}
