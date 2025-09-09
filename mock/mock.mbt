///|
struct Directory(Bytes)

///|
let uv : Result[@uv.Loop, @uv.Errno] = try? @uv.Loop::new()

///|
pub async fn directory(name : String) -> Directory raise {
  let template = @utf8.encode("maria-mock-\{name}-XXXXXX")
  if !@fs.exists(".tmp") {
    @fs.mkdir(".tmp", permission=0o755)
  }
  let tmpdir = uv
    .unwrap_or_error()
    .fs_mkdtemp_sync(@path.join(".tmp", template))
  return Directory(tmpdir)
}

///|
async fn remove_directory(path : Bytes) -> Unit raise {
  let dir = @fs.opendir(path)
  defer dir.close()
  for entry in dir.read_all() {
    let entry = @path.join(path, entry)
    match @fs.kind(entry) {
      Directory => remove_directory(entry)
      _ => @fs.remove(entry)
    }
  }
  @fs.rmdir(path)
}

///|
pub async fn Directory::close(self : Directory) -> Unit raise {
  remove_directory(self.0)
}

///|
pub fn Directory::path(self : Directory) -> String raise {
  @utf8.decode(self.0)
}

///|
pub async fn Directory::add_file(
  self : Directory,
  name : String,
  content : String,
) -> Unit raise {
  let name = @utf8.encode(name)
  let file = @fs.open(@path.join(self.0, name), mode=WriteOnly, create=0o644)
  defer file.close()
  file.write(@utf8.encode(content))
}

///|
pub async fn Directory::with_subdirectory(
  self : Directory,
  name : String,
  f : async (Directory) -> Unit raise,
) -> Unit raise {
  let name = @utf8.encode(name)
  let dir = @path.join(self.0, name)
  @fs.mkdir(dir, permission=0o755)
  f(Directory(dir))
}
