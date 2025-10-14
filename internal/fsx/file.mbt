///|
struct FileRead(@fs.File)

///|
pub async fn FileRead::create(path : StringView) -> FileRead {
  @fs.create(path.to_string(), permission=0o644)
}

///|
pub fn FileRead::close(self : FileRead) -> Unit {
  self.0.close()
}

///|
pub async fn FileRead::read_text(self : FileRead) -> String {
  self.0.read_all().text()
}

///|
struct File {
  path : String
}

///|
pub suberror IsNotFile {
  IsNotFile(path~ : String, kind~ : @fs.FileKind)
}

///|
pub impl Show for IsNotFile with output(self : IsNotFile, logger : &Logger) -> Unit {
  let IsNotFile(path~, kind~) = self
  logger.write_string("IsNotAFile(path=\{path}, kind=\{kind})")
}

///|
pub impl ToJson for IsNotFile with to_json(self : IsNotFile) -> Json {
  let IsNotFile(path~, kind~) = self
  ["InvalidFileKind", { "path": path, "kind": kind.to_string() }]
}

///|
pub suberror DoesNotExist String

///|
pub suberror Exists String

///|
pub async fn file(path : StringView) -> File {
  let path = path.to_string()
  try {
    let file = @fs.open(path, mode=@fs.ReadOnly, truncate=false)
    defer file.close()
    let kind = file.kind()
    if kind is @fs.FileKind::Directory {
      raise IsNotFile(path~, kind~)
    }
  } catch {
    @os_error.OSError(code, ..) if code == @errno.enoent => ()
    error => raise error
  }
  { path, }
}

///|
pub fn File::name(self : File) -> StringView {
  @path.basename(self.path)
}

///|
pub async fn File::read(self : File) -> String {
  @fs.read_file(self.path).text() catch {
    @os_error.OSError(code, ..) if code == @errno.enoent =>
      raise DoesNotExist(self.path)
    error => raise error
  }
}

///|
pub async fn File::write(self : File, text : StringView) -> Unit {
  @fs.write_file(self.path, text, create=0o644, truncate=true)
}
