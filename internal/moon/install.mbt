///|
async fn install(cwd? : StringView) -> Unit {
  let stdout = StringBuilder::new()
  let status = @spawn.spawn("moon", ["install"], stdout~, cwd?)
  guard status is 0 else {
    fail("moon install failed with status: \{status}\n\{stdout.to_string()}")
  }
}
