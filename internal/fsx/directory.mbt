///|
struct Directory {
  path : String
}

///|
suberror IsNotDirectory {
  IsNotDirectory(path~ : String, kind~ : @fs.FileKind)
}

///|
pub impl Show for IsNotDirectory with output(
  self : IsNotDirectory,
  logger : &Logger,
) -> Unit {
  let IsNotDirectory(path~, kind~) = self
  logger.write_string("IsNotADirectory(path=\{path}, kind=\{kind})")
}

///|
pub impl ToJson for IsNotDirectory with to_json(self : IsNotDirectory) -> Json {
  let IsNotDirectory(path~, kind~) = self
  ["InvalidDirectoryKind", { "path": path, "kind": kind.to_string() }]
}

///|
pub async fn directory(path : StringView) -> Directory {
  let path = path.to_string()
  let kind = @fs.kind(path) catch {
    @os_error.OSError(code, ..) if code == @errno.enoent =>
      raise DoesNotExist(path)
    error => raise error
  }
  guard kind is @fs.FileKind::Directory else {
    raise IsNotDirectory(path~, kind~)
  }
  { path: path.to_string() }
}

///|
pub fn Directory::path(self : Directory) -> String {
  self.path
}

///|
pub fn Directory::name(self : Directory) -> StringView {
  @path.basename(self.path)
}

///|
pub enum Entry {
  Directory(Directory)
  File(File)
}

///|
pub async fn Directory::list(self : Directory) -> Array[Entry] {
  let entries = []
  for name in @fs.readdir(self.path) {
    let path = @path.join(self.path, name)
    let entry : Entry = match @fs.kind(path) {
      Directory => Directory(Directory::{ path, })
      _ => File(File::{ path, })
    }
    entries.push(entry)
  }
  entries
}

///|
pub async fn Directory::add_file(
  self : Directory,
  name : StringView,
  content? : String,
) -> File {
  if name.contains(@path.sep.to_string()) {
    abort("file name contains path separator: \{name}")
  }
  let path = @path.join(self.path, name)
  if @fs.exists(path) {
    raise Exists(path)
  }
  if content is Some(content) {
    @fs.write_file(path, content)
  } else {
    @fs.create(path, permission=0o644).close()
  }
  File::{ path, }
}
