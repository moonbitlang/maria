///|
async fn info(package_? : String, cwd? : StringView) -> Unit {
  let arguments : Array[StringView] = ["info"]
  if package_ is Some(package_) {
    arguments.push("--package")
    arguments.push(package_)
  }
  let stdout = StringBuilder::new()
  let status = @spawn.spawn("moon", arguments, stdout~, cwd?)
  guard status is 0 else {
    fail("moon info failed with status \{status}:\n\{stdout}")
  }
}
