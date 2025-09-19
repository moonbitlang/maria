///|
priv enum TestFailureMessage {
  String(String)
  ExpectFailed(
    loc~ : String,
    args_loc~ : Array[String?],
    expect~ : String,
    actual~ : String,
    mode~ : String
  )
} derive(ToJson)

///|
impl @json.FromJson for TestFailureMessage with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> TestFailureMessage raise @json.JsonDecodeError {
  guard json is String(message) else {
    raise @json.JsonDecodeError(
      (json_path, "Expected string but got '\{json}'"),
    )
  }
  if message is [.. "@EXPECT_FAILED ", .. message] {
    let message = message.to_string()
    let json = @json.parse(message) catch {
      error =>
        raise @json.JsonDecodeError(
          (json_path, "Failed to parse EXPECT_FAILED JSON: \{error}"),
        )
    }
    guard json
      is {
        "loc": loc,
        "args_loc": args_loc,
        "expect": expect,
        "actual": actual,
        "mode": mode,
        ..
      } else {
      raise @json.JsonDecodeError(
        (
          json_path, "Expected object with 'loc', 'args_loc', 'expect', 'actual', and 'mode'.",
        ),
      )
    }
    let loc : String = @json.from_json(loc, path=json_path.add_key("loc"))
    let args_loc : String = @json.from_json(
      args_loc,
      path=json_path.add_key("args_loc"),
    )
    let args_loc = @json.parse(args_loc) catch {
      error =>
        raise @json.JsonDecodeError(
          (
            json_path.add_key("args_loc"),
            "Failed to parse args_loc JSON: \{error}",
          ),
        )
    }
    guard args_loc is Array(args_loc_json) else {
      raise @json.JsonDecodeError(
        (json_path.add_key("args_loc"), "Expected array but got '\{args_loc}'"),
      )
    }
    let args_loc : Array[String?] = []
    for arg_loc_json in args_loc_json {
      match arg_loc_json {
        Null => args_loc.push(None)
        String(arg_loc) => args_loc.push(Some(arg_loc))
        _ =>
          raise @json.JsonDecodeError(
            (
              json_path.add_key("args_loc"),
              "Expected array of strings or null but got '\{arg_loc_json}'",
            ),
          )
      }
    }
    let expect : String = @json.from_json(
      expect,
      path=json_path.add_key("expect"),
    )
    let actual : String = @json.from_json(
      actual,
      path=json_path.add_key("actual"),
    )
    let mode : String = @json.from_json(mode, path=json_path.add_key("mode"))
    ExpectFailed(loc~, args_loc~, expect~, actual~, mode~)
  } else {
    String(message)
  }
}

///|
struct TestFailure {
  package_ : String
  filename : String
  index : Int
  test_name : String
  message : TestFailureMessage
} derive(ToJson)

///|
impl @json.FromJson for TestFailure with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> TestFailure raise @json.JsonDecodeError {
  guard json
    is {
      "package": package_,
      "filename": filename,
      "index": index,
      "test_name": test_name,
      "message": message,
      ..
    } else {
    raise @json.JsonDecodeError(
      (
        json_path, "Expected object with 'package', 'filename', 'index', 'test_name', and 'message'.",
      ),
    )
  }
  let package_ : String = @json.from_json(
    package_,
    path=json_path.add_key("package"),
  )
  let filename : String = @json.from_json(
    filename,
    path=json_path.add_key("filename"),
  )
  let index : String = @json.from_json(index, path=json_path.add_key("index"))
  let index = @strconv.parse_int(index) catch {
    error =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("index"),
          "Expected integer but got '\{index}': \{error}",
        ),
      )
  }
  let test_name : String = @json.from_json(
    test_name,
    path=json_path.add_key("test_name"),
  )
  let message : TestFailureMessage = @json.from_json(
    message,
    path=json_path.add_key("message"),
  )
  TestFailure::{ package_, filename, index, test_name, message }
}

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
) -> Array[TestFailure] {
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
  let output = StringBuilder::new()
  let _ = @spawn.spawn("moon", arguments, output~, cwd?)
  let output = output.to_string()
  let failures = []
  for line in output.split("\n") {
    let json = @json.parse(line.to_string()) catch {
      // ignore non-json lines
      _ => continue
    }
    let failure : TestFailure = @json.from_json(json) catch {
      // ignore non-test-failure lines
      _ => continue
    }
    failures.push(failure)
  }
  failures
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
) -> Array[TestFailure] {
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
  let output = StringBuilder::new()
  let _ = @spawn.spawn("moon", arguments, output~, cwd?)
  let output = output.to_string()
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
