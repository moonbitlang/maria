///|
async fn install(cwd? : StringView) -> Unit {
  let result = @spawn.spawn("moon", ["install"], cwd?)
  guard result.status == 0 else {
    fail(
      "moon install failed with status: \{result.status}\n\{result.stdout}\{result.stderr}",
    )
  }
}
