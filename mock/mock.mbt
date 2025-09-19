///|
struct Directory(Bytes)

///|
pub async fn directory(name : String) -> Directory {
  let cwd = @uv.cwd()
  let template = @encoding/utf8.encode("maria-mock-\{name}-XXXXXX")
  let dot_tmp = @path.join(cwd, ".tmp")
  if !@fs.exists(dot_tmp) {
    @fs.mkdir(dot_tmp, permission=0o755)
  }
  let tmpdir = @global.uv().fs_mkdtemp_sync(@path.join(dot_tmp, template))
  return Directory(tmpdir)
}

///|
async fn remove_directory(path : Bytes) -> Unit {
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
pub async fn Directory::close(self : Directory) -> Unit {
  remove_directory(self.0)
}

///|
pub fn Directory::path(self : Directory) -> String raise {
  @encoding/utf8.decode(self.0)
}

///|
struct File(Bytes)

///|
pub fn File::path(self : File) -> String raise {
  @encoding/utf8.decode(self.0)
}

///|
pub async fn Directory::add_file(
  self : Directory,
  name : String,
  content : String,
) -> File {
  let name = @encoding/utf8.encode(name)
  let file = @fs.open(@path.join(self.0, name), mode=WriteOnly, create=0o644)
  defer file.close()
  file.write(@encoding/utf8.encode(content))
  @path.join(self.0, name)
}

///|
pub async fn Directory::with_subdirectory(
  self : Directory,
  name : String,
  f : async (Directory) -> Unit,
) -> Unit {
  let name = @encoding/utf8.encode(name)
  let dir = @path.join(self.0, name)
  @fs.mkdir(dir, permission=0o755)
  f(Directory(dir))
}

///|
pub async fn Directory::list(self : Directory) -> Array[String] {
  let dir = @fs.opendir(self.0)
  let entries = []
  for basename in dir.read_all() {
    let filename = @path.join(self.0, basename)
    let file = @fs.open(filename, mode=ReadOnly)
    defer file.close()
    let basename : Bytes = match file.kind() {
      Directory => [..basename, @path.sep]
      _ => basename
    }
    entries.push(@encoding/utf8.decode(basename))
  }
  entries.sort()
  return entries
}

///|
pub fn model() -> @model.Model {
  @model.new(
    api_key="",
    name="mock",
    base_url="mock:model",
    context_window=8192,
  )
}
