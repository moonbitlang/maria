///|
async fn info(package_? : String, cwd? : StringView) -> Unit {
  let arguments : Array[StringView] = ["info"]
  if package_ is Some(package_) {
    arguments.push("--package")
    arguments.push(package_)
  }
  let result = @spawn.spawn("moon", arguments, cwd?)
  guard result.status == 0 else {
    fail(
      "moon info failed with status \{result.status}:\n\{result.stdout}\{result.stderr}",
    )
  }
}
