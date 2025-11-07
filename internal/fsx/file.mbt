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
