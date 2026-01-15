///|
async fn test_(
  target_dir? : String,
  package_? : String,
  file? : String,
  index? : Int,
  enable_coverage? : Bool = false,
  debug? : Bool = false,
  release? : Bool = false,
  strip? : Bool = false,
  jobs? : Int,
  update? : Bool = false,
  limit? : Int,
  cwd? : StringView,
  patch_file? : String,
) -> Unit {
  let arguments : Array[StringView] = ["test", "--test-failure-json"]
  if enable_coverage {
    arguments.push("--enable-coverage")
  }
  if target_dir is Some(target_dir) {
    arguments.push("--target-dir")
    arguments.push(target_dir)
  }
  if file is Some(file) {
    arguments.push("--file")
    arguments.push(file)
  }
  if package_ is Some(package_) {
    arguments.push("--package")
    arguments.push(package_)
  }
  if index is Some(index) {
    arguments.push("--index")
    arguments.push(index.to_string())
  }
  if debug {
    arguments.push("--debug")
  }
  if release {
    arguments.push("--release")
  }
  if strip {
    arguments.push("--strip")
  } else {
    arguments.push("--no-strip")
  }
  if jobs is Some(jobs) {
    arguments.push("--jobs")
    arguments.push(jobs.to_string())
  }
  if update {
    arguments.push("--update")
  }
  if limit is Some(limit) {
    arguments.push("--limit")
    arguments.push(limit.to_string())
  }
  if patch_file is Some(patch_file) {
    arguments.push("--patch-file")
    arguments.push(patch_file)
  }
  let result = @spawn.spawn("moon", arguments, cwd?, env={ "NEW_MOON": "0" })
  result.check()
}

///|
pub async fn Module::test_(
  self : Module,
  target_dir? : String,
  package_? : String,
  file? : String,
  index? : Int,
  enable_coverage? : Bool = false,
  debug? : Bool = false,
  release? : Bool = false,
  strip? : Bool = false,
  jobs? : Int,
  update? : Bool = false,
  limit? : Int,
  patch_file? : String,
) -> Unit {
  test_(
    target_dir?,
    package_?,
    file?,
    index?,
    enable_coverage~,
    debug~,
    release~,
    strip~,
    jobs?,
    update~,
    limit?,
    cwd=self.path,
    patch_file?,
  )
}

///|
struct Artifacts {
  artifacts_path : Array[String]
} derive(ToJson)

///|
impl @json.FromJson for Artifacts with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Artifacts raise @json.JsonDecodeError {
  guard json is { "artifacts_path": artifacts_path, .. } else {
    raise @json.JsonDecodeError(
      (json_path, "Expected object with 'artifacts' key."),
    )
  }
  let artifacts_path : Array[String] = @json.from_json(
    artifacts_path,
    path=json_path.add_key("artifacts_path"),
  )
  Artifacts::{ artifacts_path, }
}

///|
async fn test_build_only(
  target_dir? : String,
  package_? : String,
  file? : String,
  index? : Int,
  enable_coverage? : Bool = false,
  debug? : Bool = false,
  release? : Bool = false,
  strip? : Bool = false,
  jobs? : Int,
  update? : Bool = false,
  limit? : Int,
  cwd? : StringView,
  patch_file? : String,
) -> Artifacts {
  let arguments : Array[StringView] = ["test", "--test-failure-json"]
  if enable_coverage {
    arguments.push("--enable-coverage")
  }
  if target_dir is Some(target_dir) {
    arguments.push("--target-dir")
    arguments.push(target_dir)
  }
  if file is Some(file) {
    arguments.push("--file")
    arguments.push(file)
  }
  if package_ is Some(package_) {
    arguments.push("--package")
    arguments.push(package_)
  }
  if index is Some(index) {
    arguments.push("--index")
    arguments.push(index.to_string())
  }
  if debug {
    arguments.push("--debug")
  }
  if release {
    arguments.push("--release")
  }
  if strip {
    arguments.push("--strip")
  } else {
    arguments.push("--no-strip")
  }
  if jobs is Some(jobs) {
    arguments.push("--jobs")
    arguments.push(jobs.to_string())
  }
  if update {
    arguments.push("--update")
  }
  if limit is Some(limit) {
    arguments.push("--limit")
    arguments.push(limit.to_string())
  }
  if patch_file is Some(patch_file) {
    arguments.push("--patch-file")
    arguments.push(patch_file)
  }
  let result = @spawn.spawn("moon", arguments, cwd?)
  let output = result.stdout + result.stderr
  for line in output.split("\n") {
    let json = @json.parse(line.to_string()) catch {
      // ignore non-json lines
      _ => continue
    }
    let artifacts : Artifacts = @json.from_json(json) catch {
      // ignore non-test-failure lines
      _ => continue
    }
    return artifacts
  } else {
    Artifacts::{ artifacts_path: [] }
  }
}

///|
pub async fn Module::test_build_only(
  self : Module,
  target_dir? : String,
  package_? : String,
  file? : String,
  index? : Int,
  enable_coverage? : Bool = false,
  debug? : Bool = false,
  release? : Bool = false,
  strip? : Bool = false,
  jobs? : Int,
  update? : Bool = false,
  limit? : Int,
  patch_file? : String,
) -> Artifacts {
  test_build_only(
    target_dir?,
    package_?,
    file?,
    index?,
    enable_coverage~,
    debug~,
    release~,
    strip~,
    jobs?,
    update~,
    limit?,
    cwd=self.path,
    patch_file?,
  )
}
