///|
struct Directory(String)

///|
/// Returns the absolute filesystem path represented by this mock directory.
pub fn Directory::path(self : Directory) -> String {
  self.0
}

///|
async fn directory(path : String) -> Directory {
  @mfs.make_directory(path, recursive=true, exists_ok=true)
  let path = @fs.realpath(path)
  Directory(path)
}

///|
priv struct Clock {
  mut timestamp : Int64
}

///|
impl @clock.Clock for Clock with now(self : Clock) -> Int64 {
  let ts = self.timestamp
  self.timestamp += 1
  ts
}

///|
impl @clock.Clock for Clock with now_str(self : Clock) -> String {
  let t = self.now()
  "Tick:\{t}"
}

///|
pub struct Context {
  cwd : Directory
  logger : @pino.Logger
  clock : &@clock.Clock
  rand : @random.Rand
  uuid : @uuid.Generator
  filter : Filter
  group : @async.TaskGroup[Unit]
  moon_home : String
}

///|
async fn Context::close(self : Context) -> Unit {
  @fs.rmdir(self.cwd.0, recursive=true)
}

///|
/// Adds a file inside the mock workspace, overwriting any existing content.
pub async fn Context::add_file(
  self : Context,
  name : String,
  content? : String,
) -> File {
  self.cwd.add_file(name, content?)
}

///|
/// Creates multiple files under the mock workspace in a single batch.
pub async fn Context::add_files(
  self : Context,
  files : Array[(String, String)],
) -> Unit {
  for item in files {
    self.cwd.add_file(item.0, content=item.1) |> ignore
  }
}

///|
/// TODO(upstream): implement symlink()
pub async fn Context::add_symlink(
  self : Context,
  link : String,
  to~ : String,
) -> Unit {
  let link_path = @path.join(self.cwd.path(), link)
  let status = @process.run("ln", ["-s", to, link_path])
  guard status is 0 else {
    fail("Failed to create symlink '\{link_path}' -> '\{to}'")
  }
}

///|
/// Creates a subdirectory relative to the mock workspace root and returns it.
pub async fn Context::add_directory(self : Context, name : String) -> Directory {
  self.cwd.add_directory(name)
}

///|
struct Filter {
  keywords : Array[(String, String)]
}

///|
fn Filter::new() -> Filter {
  Filter::{ keywords: [] }
}

///|
fn Filter::add(self : Filter, key : String, value : String) -> Unit {
  self.keywords.push((key, value))
}

///|
priv trait Filterable {
  filter(self : Filter, value : Self) -> Self
}

///|
impl Filterable for String with filter(self : Filter, content : String) -> String {
  let mut content = content
  for keyword in self.keywords {
    let (key, value) = keyword
    content = content.replace_all(old=value, new="(mock:\{key})")
  }
  content
}

///|
impl Filterable for Json with filter(self : Filter, value : Json) -> Json {
  match value {
    String(string) => Json::string(Filterable::filter(self, string))
    Array(array) => Json::array(array.map(e => Filterable::filter(self, e)))
    Object(old_object) => {
      let new_object = {}
      for k, v in old_object {
        new_object[Filterable::filter(self, k)] = Filterable::filter(self, v)
      }
      Json::object(new_object)
    }
    _ => value
  }
}

///|
/// Serializes a value to JSON while masking sensitive fields with the current filter.
pub fn[T : ToJson] Context::json(self : Context, value : T) -> Json {
  Filterable::filter(self.filter, value.to_json())
}

///|
/// Formats a value into a filtered string suited for deterministic snapshots.
#alias(text)
pub fn[T : Show] Context::show(self : Context, value : T) -> String {
  Filterable::filter(self.filter, value.to_string())
}

///|
let home_lock : @semaphore.Semaphore = @semaphore.Semaphore::new(1)

///|
/// Temporarily points `HOME` to the provided directory while running `f`.
pub async fn[T] with_home(directory : Directory, f : async () -> T) -> T {
  home_lock.acquire()
  let home = @os.home()
  @os.setenv("HOME", directory.path(), overwrite=true)
  try f() catch {
    error => {
      @os.setenv("HOME", home, overwrite=true)
      home_lock.release()
      raise error
    }
  } noraise {
    value => {
      @os.setenv("HOME", home, overwrite=true)
      home_lock.release()
      value
    }
  }
}

///|
/// Writes a file relative to this directory and returns a handle to it.
pub async fn Directory::add_file(
  self : Directory,
  name : String,
  content? : String = "",
) -> File {
  let path = @path.join(self.0, name)
  @fs.write_file(path, content, truncate=true, create=0o644)
  File(path)
}

///|
/// Creates a nested directory relative to this directory and returns it.
pub async fn Directory::add_directory(
  self : Directory,
  name : String,
) -> Directory {
  let path = @path.join(self.0, name)
  @fs.mkdir(path, permission=0o755)
  Directory(path)
}

///|
struct File(String)

///|
/// Returns the absolute filesystem path for this mock file.
pub fn File::path(self : File) -> String {
  self.0
}

///|
/// Reads the entire file contents as a UTF-8 string.
pub async fn File::read(self : File) -> String {
  @fs.read_file(self.0).text()
}

///|
/// Replaces the file contents with the provided string.
pub async fn File::write(self : File, content : String) -> Unit {
  @fs.write_file(self.0, content)
}

///|
pub enum Entry {
  Directory(Directory)
  File(File)
}

///|
fn Entry::path(self : Entry) -> String {
  match self {
    Directory(dir) => dir.path()
    File(file) => file.path()
  }
}

///|
/// Returns the final path component for this directory or file entry.
pub fn Entry::name(self : Entry) -> StringView {
  @path.basename(self.path())
}

///|
/// Lists the immediate entries contained in this directory.
pub async fn Directory::list(self : Directory) -> Array[Entry] {
  let entries = []
  for name in @fs.readdir(self.0) {
    let path = @path.join(self.0, name)
    let entry : Entry = match @fs.kind(path) {
      Directory => Directory(path)
      _ => File(path)
    }
    entries.push(entry)
  }
  entries
}

///|
let os_args : Array[String] = @os.args()

///|
/// Retrieves the value of an environment variable, raising an error if it is
/// not set or empty (unless `allow_empty` is true). The retrieved value is also
/// added to the context's filter for masking in outputs.
pub fn Context::getenv(
  self : Context,
  key : String,
  allow_empty? : Bool = false,
) -> String raise {
  guard @os.getenv(key) is Some(value) else {
    fail("Environment variable '\{key}' not set")
  }
  if !allow_empty && value is "" {
    fail("Environment variable '\{key}' is empty")
  }
  self.filter.add("env:\{key}", value)
  value
}

///|
pub fn Context::model(
  self : Context,
  name? : @model.CommonModels = @model.Qwen3CoderPlus,
) -> @model.Model raise {
  @model.open_router_model(api_key=self.getenv("OPENROUTER_API_KEY"), name~)
}

///|
/// Runs a test function within an isolated mock environment with controlled
/// resources and automatic cleanup.
///
/// Parameters:
///
/// * `t` : The test instance that provides the test name and context.
/// * `loc` : The source location where this function is called (automatically
///   filled by the compiler).
/// * `timeout` (Optional) : timeout in milliseconds for the test execution
///   (defaults to 30,000ms).
/// * `retry` (Optional) : number of retry attempts if the test fails.
/// * `f` : The async test function to execute, which receives a mock `Context`
///   with isolated filesystem, logger, clock, and other utilities.
///
/// Throws an error of type `@errno.Errno` if temporary directory creation
/// fails, or propagates any error thrown by the test function (except `Skip`
/// errors which are silently ignored).
///
/// Panics if the executable path structure doesn't match the expected MoonBit
/// project layout (`["target", "native", "debug" | "release", "test", .. parts,
/// _]`).
///
/// Example:
///
/// ```moonbit async
/// async test (t : @test.Test) {
///   @mock.run(t, ctx => {
///     let file = ctx.add_file("test.txt", content="Hello, World!")
///     let content = file.read()
///     @json.inspect(content, content="Hello, World!")
///   })
/// }
/// ```
#callsite(autofill(loc))
pub async fn run(
  t : @test.Test,
  loc~ : SourceLoc,
  timeout? : Int = 300_000,
  retry? : Int,
  action : async (Context) -> Unit,
) -> Unit {
  let os_cwd = @os.cwd()
  let exec = os_args[0]
  let exec = @path.relative(os_cwd, exec)
  let exec_parts = @path.split(exec).collect()
  guard exec_parts
    is ["target", "native", "debug" | "release", "test", .. parts, _] else {
    abort(
      "Unexpected executable path, @mock should only be used in test: \{exec}",
    )
  }
  let pkg_path = parts.join(@path.sep.to_string())
  // `@mfs.with_temporary_directory` internally joins the `@os.tmpdir()` path
  @mfs.with_temporary_directory("moonbit-taco-XXXXXXX", tmpdir => {
    let tmp_pkg_path = @path.join(tmpdir, pkg_path)
    async fn run() -> Unit {
      @async.with_timeout(timeout, () => @async.with_task_group(group => {
        let cwd = directory(@path.join(tmp_pkg_path, t.name()))
        let log_dir = os_cwd |> @path.join("__trajectories__")
        @fs.mkdir(log_dir, permission=0o755) catch {
          _ => ()
        }
        let logged = log_dir |> @path.join("\{t.name()}.jsonl")
        let logger = @pino.logger(t.name(), @pino.Transport::file(logged))
        let clock = Clock::{ timestamp: 0 }
        let rand = @random.Rand::chacha8(seed=Bytes::make(32, 0))
        let uuid = @uuid.generator(rand)
        let file = loc.to_string().split(":").peek().unwrap().to_string()
        // setup filter
        let home = @os.home()
        let moon_home = @os.getenv("MOON_HOME").unwrap_or_else(() => @path.join(
          home, ".moon",
        ))
        let filter = Filter::new()
        filter
        ..add("file", file)
        ..add("cwd", cwd.path())
        ..add("env:MOON_HOME", moon_home)
        ..add("env:HOME", directory(@os.home()).path())
        if @os.getenv("OPENAI_API_KEY") is Some(api_key) && api_key != "" {
          filter.add("env:OPENAI_API_KEY", api_key)
        }
        let ctx = Context::{
          cwd,
          logger,
          clock,
          rand,
          uuid,
          filter,
          group,
          moon_home,
        }
        group.add_defer(() => ctx.close())
        action(ctx)
      }))
    }

    if retry is Some(retry) {
      @async.retry(Immediate, max_retry=retry, run)
    } else {
      run()
    }
  })
}
