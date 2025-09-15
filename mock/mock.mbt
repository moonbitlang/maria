///|
struct Directory(Bytes)

///|
pub async fn directory(name : String) -> Directory raise {
  let template = @utf8.encode("maria-mock-\{name}-XXXXXX")
  if !@fs.exists(".tmp") {
    @fs.mkdir(".tmp", permission=0o755)
  }
  let tmpdir = @global.uv().fs_mkdtemp_sync(@path.join(".tmp", template))
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
struct File(Bytes)

///|
pub fn File::path(self : File) -> String raise {
  @utf8.decode(self.0)
}

///|
pub async fn Directory::add_file(
  self : Directory,
  name : String,
  content : String,
) -> File raise {
  let name = @utf8.encode(name)
  let file = @fs.open(@path.join(self.0, name), mode=WriteOnly, create=0o644)
  defer file.close()
  file.write(@utf8.encode(content))
  @path.join(self.0, name)
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

///|
pub async fn Directory::list(self : Directory) -> Array[String] raise {
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
    entries.push(@utf8.decode(basename))
  }
  entries.sort()
  return entries
}
