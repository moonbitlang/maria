///|
struct Directory(String)

///|
pub fn Directory::path(self : Directory) -> String {
  self.0
}

///|
async fn directory(path : String) -> Directory {
  let dirs = []
  for dir = path.view() {
    let dir = dir.to_string()
    if dir == "." || dir == "" || @fs.exists(dir) {
      break
    }
    dirs.push(dir)
    continue @path.dirname(dir)
  }
  for i in 0..<dirs.length() {
    let dir = dirs[dirs.length() - 1 - i]
    @fs.mkdir(dir, permission=0o755)
  }
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
pub struct Context {
  priv file : String
  cwd : Directory
  logger : @pino.Logger
  clock : &@clock.Clock
  rand : @random.Rand
  uuid : @uuid.Generator
}

///|
async fn Context::close(self : Context) -> Unit {
  @fs.rmdir(self.cwd.0, recursive=true)
}

///|
pub async fn Context::add_file(
  self : Context,
  name : String,
  content? : String,
) -> File {
  self.cwd.add_file(name, content?)
}

///|
pub async fn Context::add_directory(self : Context, name : String) -> Directory {
  self.cwd.add_directory(name)
}

///|
priv trait Filter {
  filter(self : Context, value : Self) -> Self
}

///|
impl Filter for String with filter(self : Context, value : String) -> String {
  value
  .replace_all(old=self.cwd.path(), new=".")
  .replace_all(old=self.file.to_string(), new="(taco:file)")
}

///|
impl Filter for Json with filter(self : Context, value : Json) -> Json {
  match value {
    String(string) => Json::string(Filter::filter(self, string))
    Array(array) => Json::array(array.map(e => Filter::filter(self, e)))
    Object(old_object) => {
      let new_object = {}
      for k, v in old_object {
        new_object[Filter::filter(self, k)] = Filter::filter(self, v)
      }
      Json::object(new_object)
    }
    _ => value
  }
}

///|
pub fn[T : ToJson] Context::json(self : Context, value : T) -> Json {
  Filter::filter(self, ToJson::to_json(value))
}

///|
pub fn[T : Show] Context::show(self : Context, value : T) -> String {
  Filter::filter(self, Show::to_string(value))
}

///|
let home_lock : @semaphore.Semaphore = @semaphore.Semaphore::new(1)

///|
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
pub fn File::path(self : File) -> String {
  self.0
}

///|
pub async fn File::read(self : File) -> String {
  @fs.read_file(self.0).text()
}

///|
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
pub fn Entry::name(self : Entry) -> StringView {
  @path.basename(self.path())
}

///|
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
#borrow(template)
extern "c" fn fs_mkdtemp(template : Bytes) -> Int = "moonbit_maria_fs_mkdtemp"

///|
#callsite(autofill(loc))
pub async fn[T] run(
  t : @test.T,
  loc~ : SourceLoc,
  f : async (Context) -> T,
) -> T {
  let os_cwd = @os.cwd()
  let os_tmpdir = @os.tmpdir()
  let exec = os_args[0]
  let exec = @path.relative(os_cwd, exec)
  let exec_parts = @path.split(exec).collect()
  guard exec_parts
    is ["target", "native", "debug" | "release", "test", .. parts, _]
  let pkg_path = parts.join(@path.sep.to_string())
  let template : String = @path.join(os_tmpdir, "moonbit-taco-XXXXXXX")
  let template = @encoding/utf8.encode(template)
  let errno = fs_mkdtemp(template)
  if errno != 0 {
    raise @errno.Errno(errno)
  }
  let template = @encoding/utf8.decode(template)
  let tmp_pkg_path = @path.join(template, pkg_path)
  @async.with_timeout(10_000, () => @async.with_task_group(group => {
    let cwd = directory(@path.join(tmp_pkg_path, t.name()))
    let logger = @pino.logger(t.name(), @pino.Transport::sink())
    let clock = Clock::{ timestamp: 0 }
    let rand = @random.Rand::chacha8(seed=Bytes::make(32, 0))
    let uuid = @uuid.generator(rand)
    let file = loc.to_string().split(":").peek().unwrap().to_string()
    let ctx = Context::{ file, cwd, logger, clock, rand, uuid }
    group.add_defer(() => ctx.close())
    f(ctx)
  }))
}
