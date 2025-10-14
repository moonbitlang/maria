///|
struct Coverage {
  path : String
}

///|
async fn coverage_analyze(
  package_? : String,
  file? : String,
  cwd? : StringView,
) -> String {
  let arguments : Array[StringView] = ["coverage", "analyze"]
  if package_ is Some(package_) {
    arguments.push("--package")
    arguments.push(package_)
  }
  arguments.push("--")
  if file is Some(file) {
    arguments.push("-F")
    arguments.push(file)
  }
  let output = StringBuilder::new()
  let _ = @spawn.spawn("moon", arguments, stdout=output, stderr=output, cwd?)
  output.to_string()
}

///|
pub async fn Coverage::analyze(
  self : Coverage,
  package_? : Package,
  file? : String,
) -> String {
  let package_ = match package_ {
    Some(package_) => Some(package_.name)
    None => None
  }
  coverage_analyze(package_?, file?, cwd=self.path)
}

///|
async fn coverage_clean(package_? : String, cwd? : StringView) -> String {
  let arguments : Array[StringView] = ["coverage", "clean"]
  if package_ is Some(package_) {
    arguments.push("--package")
    arguments.push(package_)
  }
  let output = StringBuilder::new()
  let _ = @spawn.spawn("moon", arguments, stdout=output, stderr=output, cwd?)
  output.to_string()
}

///|
pub async fn Coverage::clean(self : Coverage, package_? : String) -> String {
  coverage_clean(package_?, cwd=self.path)
}

///|
pub(all) enum CoverageFormat {
  Bisect
  Caret
  Coveralls
  Cobertura
  Html
  Summary
}

///|
pub impl Show for CoverageFormat with output(
  self : CoverageFormat,
  logger : &Logger,
) -> Unit {
  match self {
    Bisect => logger.write_string("bisect")
    Caret => logger.write_string("caret")
    Coveralls => logger.write_string("coveralls")
    Cobertura => logger.write_string("cobertura")
    Html => logger.write_string("html")
    Summary => logger.write_string("summary")
  }
}

///|
async fn coverage_report(
  package_? : String,
  output_file? : String,
  format? : CoverageFormat,
  cwd? : StringView,
) -> String {
  let arguments : Array[StringView] = ["coverage", "report"]
  if package_ is Some(package_) {
    arguments.push("-p")
    arguments.push(package_)
  }
  if format is Some(format) {
    arguments.push("-f")
    arguments.push(format.to_string())
  }
  if output_file is Some(output_file) {
    arguments.push("-o")
    arguments.push(output_file)
  }
  let output = StringBuilder::new()
  let status = @spawn.spawn(
    "moon",
    arguments,
    stdout=output,
    stderr=output,
    cwd?,
  )
  guard status == 0 else {
    fail("Failed to generate coverage report:\n\{output}")
  }
  output.to_string()
}

///|
pub async fn Coverage::report(
  self : Coverage,
  package_? : String,
  output_file? : String,
  format? : CoverageFormat,
) -> String {
  coverage_report(package_?, output_file?, format?, cwd=self.path)
}
