///|
async fn coverage_analyze(package_? : String, cwd? : StringView) -> String {
  let arguments : Array[StringView] = ["coverage", "analyze"]
  if package_ is Some(package_) {
    arguments.push("--package")
    arguments.push(package_)
  }
  let output = StringBuilder::new()
  let _ = @spawn.spawn("moon", arguments, output~, cwd?)
  output.to_string()
}

///|
pub async fn Module::coverage_analyze(
  self : Module,
  package_? : String,
) -> String {
  coverage_analyze(package_?, cwd=self.path)
}
