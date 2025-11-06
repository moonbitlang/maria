///|
async fn install(cwd? : StringView) -> Unit {
  let output = StringBuilder::new()
  let status = @spawn.spawn(
    "moon",
    ["install"],
    stdout=output,
    stderr=output,
    cwd?,
  )
  guard status is 0 else {
    fail("moon install failed with status: \{status}\n\{output.to_string()}")
  }
}
